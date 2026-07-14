import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../domain/repositories/i_litter_repository.dart';
import '../../../breeders/domain/repositories/i_breeder_repository.dart';
import '../../../puppies/domain/repositories/i_puppy_repository.dart';

class LitterDetailViewModel extends ChangeNotifier {
  final ILitterRepository _litterRepository;
  final IBreederRepository _breederRepository;
  final IPuppyRepository _puppyRepository;

  LitterDetailViewModel({
    required ILitterRepository litterRepository,
    required IBreederRepository breederRepository,
    required IPuppyRepository puppyRepository,
  }) : _litterRepository = litterRepository,
       _breederRepository = breederRepository,
       _puppyRepository = puppyRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Litter? _litter;
  Litter? get litter => _litter;

  Breeder? _mother;
  Breeder? get mother => _mother;

  Breeder? _father;
  Breeder? get father => _father;

  List<Puppy> _puppies = [];
  List<Puppy> get puppies => _puppies;

  Future<void> loadLitterDetail(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _litter = await _litterRepository.getLitter(id);
      if (_litter != null) {
        _mother = await _breederRepository.getBreeder(_litter!.motherId);
        if (_litter!.fatherId != null) {
          _father = await _breederRepository.getBreeder(_litter!.fatherId!);
        } else {
          _father = null;
        }
        _puppies = await _puppyRepository.getPuppies(_litter!.id!);
      }
    } catch (_) {
      // Ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
