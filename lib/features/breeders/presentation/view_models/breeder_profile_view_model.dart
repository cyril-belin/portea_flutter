import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../domain/repositories/i_breeder_repository.dart';

class BreederProfileViewModel extends ChangeNotifier {
  final IBreederRepository _breederRepository;

  BreederProfileViewModel({required IBreederRepository breederRepository})
    : _breederRepository = breederRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Breeder? _breeder;
  Breeder? get breeder => _breeder;

  Future<void> loadBreeder(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _breeder = await _breederRepository.getBreeder(id);
    } catch (_) {
      // Ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setupNewBreeder() {
    _breeder = null;
    notifyListeners();
  }

  Future<bool> saveBreeder({
    required String name,
    required String sex,
    required String breed,
    required DateTime? birthDate,
    required String chipNumber,
    required String tattooNumber,
    required String status,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_breeder == null) {
        final newBreeder = Breeder(
          name: name,
          sex: sex,
          breed: breed,
          birthDate: birthDate,
          chipNumber: chipNumber.isEmpty ? null : chipNumber,
          tattooNumber: tattooNumber.isEmpty ? null : tattooNumber,
          status: status,
          kennelId: 1, // Default mock kennel id
        );
        await _breederRepository.createBreeder(newBreeder);
      } else {
        _breeder!.name = name;
        _breeder!.sex = sex;
        _breeder!.breed = breed;
        _breeder!.birthDate = birthDate;
        _breeder!.chipNumber = chipNumber.isEmpty ? null : chipNumber;
        _breeder!.tattooNumber = tattooNumber.isEmpty ? null : tattooNumber;
        _breeder!.status = status;
        await _breederRepository.updateBreeder(_breeder!);
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
