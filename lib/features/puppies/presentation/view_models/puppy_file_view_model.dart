import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/operation_state.dart';
import '../../domain/repositories/i_puppy_repository.dart';
import '../../domain/repositories/i_weighing_repository.dart';
import '../../domain/repositories/i_care_repository.dart';
import '../../../settings/domain/repositories/i_settings_repository.dart';

class PuppyFileViewModel extends ChangeNotifier {
  final IPuppyRepository _puppyRepository;
  final IWeighingRepository _weighingRepository;
  final ICareRepository _careRepository;
  final ISettingsRepository _settingsRepository;

  PuppyFileViewModel({
    required IPuppyRepository puppyRepository,
    required IWeighingRepository weighingRepository,
    required ICareRepository careRepository,
    required ISettingsRepository settingsRepository,
  }) : _puppyRepository = puppyRepository,
       _weighingRepository = weighingRepository,
       _careRepository = careRepository,
       _settingsRepository = settingsRepository;

  OperationState _state = OperationState.idle;
  OperationState get state => _state;

  bool get isBusy =>
      _state == OperationState.loading ||
      _state == OperationState.refreshing ||
      _state == OperationState.mutating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Puppy? _puppy;
  Puppy? get puppy => _puppy;

  List<WeighingEntry> _weighings = [];
  // Claim 2.6: never expose the mutable backing list.
  List<WeighingEntry> get weighings => List.unmodifiable(_weighings);

  List<CareEntry> _careTimeline = [];
  // Claim 2.6: never expose the mutable backing list.
  List<CareEntry> get careTimeline => List.unmodifiable(_careTimeline);

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Future<void> loadPuppyFile(int id) async {
    // Refresh vs first load: existing file stays visible during a reload.
    final hasData = _puppy != null;
    _state = hasData ? OperationState.refreshing : OperationState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _isPremium = await _settingsRepository.isPremium();
      _puppy = await _puppyRepository.getPuppy(id);
      if (_puppy != null) {
        _weighings = await _weighingRepository.getWeighings(id);
        _careTimeline = await _careRepository.getCareEntries(puppyId: id);
      }
      _state = OperationState.success;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Snapshot helper for optimistic-mutation rollback. Serverpod model fields
  /// are mutable, so we clone the values we may touch before the await.
  Puppy _snapshot() => Puppy(
    id: _puppy!.id,
    litterId: _puppy!.litterId,
    name: _puppy!.name,
    sex: _puppy!.sex,
    color: _puppy!.color,
    status: _puppy!.status,
    chipNumber: _puppy!.chipNumber,
    birthWeight: _puppy!.birthWeight,
    photoUrl: _puppy!.photoUrl,
    buyerName: _puppy!.buyerName,
    buyerPhone: _puppy!.buyerPhone,
    buyerEmail: _puppy!.buyerEmail,
    buyerAddress: _puppy!.buyerAddress,
  );

  Future<void> updateStatus(String status) async {
    if (_puppy == null) return;
    if (_state == OperationState.mutating) return;
    final previous = _snapshot();
    _puppy!.status = status;
    _state = OperationState.mutating;
    _errorMessage = null;
    notifyListeners();

    try {
      await _puppyRepository.updatePuppy(_puppy!);
      _state = OperationState.success;
    } catch (e) {
      _puppy = previous;
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> saveBuyerInfo({
    required String name,
    required String phone,
    required String email,
    required String address,
  }) async {
    if (_puppy == null) return;
    if (_state == OperationState.mutating) return;
    final previous = _snapshot();
    _puppy!.buyerName = name.isEmpty ? null : name;
    _puppy!.buyerPhone = phone.isEmpty ? null : phone;
    _puppy!.buyerEmail = email.isEmpty ? null : email;
    _puppy!.buyerAddress = address.isEmpty ? null : address;
    _state = OperationState.mutating;
    _errorMessage = null;
    notifyListeners();

    try {
      await _puppyRepository.updatePuppy(_puppy!);
      _state = OperationState.success;
    } catch (e) {
      _puppy = previous;
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> addSingleWeight(double weightGrams) async {
    if (_puppy == null) return;
    if (_state == OperationState.mutating) return;
    _state = OperationState.mutating;
    _errorMessage = null;
    notifyListeners();

    try {
      final entry = WeighingEntry(
        puppyId: _puppy!.id!,
        weighedAt: DateTime.now(),
        weightGrams: weightGrams,
      );
      await _weighingRepository.addWeighing(entry);
      _weighings = await _weighingRepository.getWeighings(_puppy!.id!);
      _state = OperationState.success;
    } catch (e) {
      _errorMessage = mapExceptionToMessage(e);
      _state = OperationState.error;
    } finally {
      notifyListeners();
    }
  }
}
