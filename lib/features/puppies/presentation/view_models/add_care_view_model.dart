import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/operation_state.dart';
import '../../../../core/notifications/inotification_service.dart';
import '../../domain/repositories/i_care_repository.dart';

/// View model for the add-care form.
///
/// Handles the two paths from the F06 spec:
/// - group care (the whole litter): a SINGLE call to
///   [ICareRepository.addGroupCare] — the server builds the parent entry
///   (litterId, reminderAt) and one child per puppy (puppyId, reminderAt
///   null) in one transaction;
/// - individual care (one puppy): a single call to
///   [ICareRepository.addCareEntry], where reminderAt lands on the puppy's
///   own entry.
///
/// This rewrite removes the old client-side loop (review claim 4.3): it
/// created entries one by one AND copied reminderAt onto every child, which
/// would have spammed N identical notifications once F07 schedules per
/// non-null reminderAt. The server is now the authority — the contract
/// (`addGroupCare` takes individual params) makes a client-side reminderAt on
/// children impossible by construction.
///
/// Error handling follows the project-wide pattern: the catch maps the
/// exception via [mapExceptionToMessage], stores it in [errorMessage], and
/// sets [state] to [OperationState.error]. The typed care exceptions
/// (`InvalidCareRelationException`, `InvalidCareInputException`) are mapped to
/// their French business message; everything else falls through to the
/// mapper's transport/generic branches.
class AddCareViewModel extends ChangeNotifier {
  AddCareViewModel({
    required ICareRepository careRepository,
    INotificationService? notificationService,
  }) : _careRepository = careRepository,
       _notificationService = notificationService;

  final ICareRepository _careRepository;
  final INotificationService? _notificationService;

  OperationState _state = OperationState.idle;
  OperationState get state => _state;

  bool get isBusy =>
      _state == OperationState.loading ||
      _state == OperationState.refreshing ||
      _state == OperationState.mutating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Saves a care entry. Returns true on success, false on error (with
  /// [errorMessage] populated). Mutations are ignored while another mutation
  /// is in flight (double-submit guard).
  ///
  /// [targetAllLitter] + [litterId] → group care (single `addGroupCare`).
  /// Otherwise → individual care (single `addCareEntry`).
  ///
  /// [targetName] is the reminder target's display name (puppy name for
  /// individual care, mother name for group care) — resolved by the screen
  /// from already-loaded data. Passed through to the notification title (F07
  /// rule 7). The view model does NO name lookup itself.
  Future<bool> saveCareEntry({
    required String type, // 'vaccine' | 'deworming' | 'other'
    required String product,
    required DateTime date,
    int? puppyId,
    int? litterId,
    bool targetAllLitter = false,
    DateTime? reminderDate,
    String? targetName,
    String? notes,
  }) async {
    if (_state == OperationState.mutating) return false;
    _state = OperationState.mutating;
    _errorMessage = null;
    notifyListeners();

    try {
      // The entry that carries the reminderAt (and so the one a notification is
      // scheduled from): the puppy's own entry for individual care, the parent
      // for group care. Captured from the repository return — NOT discarded.
      CareEntry? reminderEntry;
      if (targetAllLitter && litterId != null) {
        // Group care — one call. The server builds the parent (litterId +
        // reminderAt) and one child per puppy (puppyId + reminderAt null) in
        // a single transaction. No client-side loop, no reminderAt on
        // children — the central F06 rule.
        final created = await _careRepository.addGroupCare(
          litterId: litterId,
          type: type,
          product: product,
          appliedAt: date,
          reminderAt: reminderDate,
          notes: notes,
        );
        reminderEntry = created.isEmpty ? null : created.first;
      } else {
        // Individual care: reminderAt lands directly on the puppy's own entry
        // (no parent — there is no group).
        reminderEntry = await _careRepository.addCareEntry(
          CareEntry(
            type: type,
            product: product,
            appliedAt: date,
            puppyId: puppyId,
            reminderAt: reminderDate,
            notes: notes,
          ),
        );
      }
      _state = OperationState.success;
      notifyListeners();

      // F07: schedule the OS reminder AFTER a successful persist. The id is the
      // persisted entry's id (stable, idempotent). Rule 4: NEVER cancel other
      // reminders here — scheduling the same id just replaces it. A scheduling
      // failure is swallowed so a successful save stays successful.
      await _scheduleReminderIfAny(
        reminderEntry,
        isGroup: targetAllLitter && litterId != null,
        targetName: targetName,
      );
      return true;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
      notifyListeners();
      return false;
    }
  }

  /// Schedules the OS reminder for [entry] when it carries a future reminderAt
  /// and a persisted id. Best-effort: any failure (no service, OS denied, past
  /// date) is swallowed — the care entry is already saved, so a reminder glitch
  /// must not turn a success into a failure.
  ///
  /// Title/body follow F07 rule 7: title includes the target name (puppy name
  /// for individual care, mother name for group care) passed in by the screen;
  /// body is `{Type} — {produit}` (product omitted when blank). Rule 4: this
  /// only schedules — it never cancels another reminder.
  Future<void> _scheduleReminderIfAny(
    CareEntry? entry, {
    required bool isGroup,
    String? targetName,
  }) async {
    final service = _notificationService;
    if (service == null) return;
    final id = entry?.id;
    final reminderAt = entry?.reminderAt;
    if (id == null || reminderAt == null) return;

    // Payload: `/puppies/<id>` for individual care, `/litters/<id>` for group
    // care (the parent carries the reminderAt).
    final payload = entry!.puppyId != null
        ? '/puppies/${entry.puppyId}'
        : '/litters/${entry.litterId}';

    try {
      await service.scheduleReminder(
        notificationId: id,
        scheduledAt: reminderAt,
        title: isGroup
            ? reminderTitle(motherName: targetName)
            : reminderTitle(puppyName: targetName),
        body: reminderBody(type: entry.type, product: entry.product),
        payload: payload,
      );
    } catch (_) {
      // Swallowed: the care entry is persisted; the reminder is best-effort.
    }
  }
}
