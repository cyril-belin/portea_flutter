import 'package:portea_client/portea_client.dart';

/// Care repository contract.
///
/// Mirrors the server `CareEndpoint` (see `care_endpoint.dart` for the full
/// authorization, validation and transactional guarantees). Kennel scoping is
/// enforced server-side — the client never passes a kennelId.
///
/// THE CENTRAL RULE (review claim 4.3 + F06 spec): group care routes through
/// [addGroupCare], which takes individual params. The server builds ONE parent
/// entry (litterId, reminderAt) + ONE child entry per puppy (puppyId,
/// reminderAt forced null). By contract the client CANNOT pass a reminderAt
/// per child — the rule is enforced by construction, not by trust. Individual
/// care routes through [addCareEntry], where reminderAt lands directly on the
/// puppy's own entry.
abstract class ICareRepository {
  /// Individual care entries of a puppy, most recent first. When [litterId] is
  /// set instead, returns the group-care PARENT entries of a litter (the
  /// per-puppy children are NOT included — fetch them per-puppy). Exactly one
  /// of [puppyId] / [litterId] should be set.
  Future<List<CareEntry>> getCareEntries({int? puppyId, int? litterId});

  /// Adds a single INDIVIDUAL care entry. [entry.puppyId] must be set;
  /// [entry.reminderAt] lands directly on the puppy's own entry.
  Future<CareEntry> addCareEntry(CareEntry entry);

  /// Adds GROUP care for a whole litter. The server creates ONE parent entry
  /// (litterId, reminderAt) + ONE child entry per puppy (puppyId, reminderAt
  /// null). [reminderAt] applies to the parent only — the children never carry
  /// one. Returns the created entries (parent first, then children).
  Future<List<CareEntry>> addGroupCare({
    required int litterId,
    required String type,
    String? product,
    required DateTime appliedAt,
    DateTime? reminderAt,
    String? notes,
  });

  /// Next [limit] reminders (reminderAt non-null and in the future) scoped to
  /// the session's kennel, earliest first. Because group care puts reminderAt
  /// on the parent only, each group yields exactly one reminder — no spam.
  Future<List<CareEntry>> getUpcomingReminders(int limit);
}
