import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Puppy? _puppy;
  Puppy? get puppy => _puppy;

  List<WeighingEntry> _weighings = [];
  List<WeighingEntry> get weighings => _weighings;

  List<CareEntry> _careTimeline = [];
  List<CareEntry> get careTimeline => _careTimeline;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Future<void> loadPuppyFile(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _isPremium = await _settingsRepository.isPremium();
      _puppy = await _puppyRepository.getPuppy(id);
      if (_puppy != null) {
        _weighings = await _weighingRepository.getWeighings(id);
        _careTimeline = await _careRepository.getCareEntries(puppyId: id);
      }
    } catch (_) {
      // Ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String status) async {
    if (_puppy == null) return;
    _puppy!.status = status;
    await _puppyRepository.updatePuppy(_puppy!);
    notifyListeners();
  }

  Future<void> saveBuyerInfo({
    required String name,
    required String phone,
    required String email,
    required String address,
  }) async {
    if (_puppy == null) return;
    _puppy!.buyerName = name.isEmpty ? null : name;
    _puppy!.buyerPhone = phone.isEmpty ? null : phone;
    _puppy!.buyerEmail = email.isEmpty ? null : email;
    _puppy!.buyerAddress = address.isEmpty ? null : address;
    await _puppyRepository.updatePuppy(_puppy!);
    notifyListeners();
  }

  Future<void> addSingleWeight(double weightGrams) async {
    if (_puppy == null) return;
    final entry = WeighingEntry(
      puppyId: _puppy!.id!,
      weighedAt: DateTime.now(),
      weightGrams: weightGrams,
    );
    await _weighingRepository.addWeighing(entry);
    _weighings = await _weighingRepository.getWeighings(_puppy!.id!);
    notifyListeners();
  }
}
