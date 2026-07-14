import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../domain/repositories/i_litter_repository.dart';
import '../../../breeders/domain/repositories/i_breeder_repository.dart';

class LitterDeclarationViewModel extends ChangeNotifier {
  final ILitterRepository _litterRepository;
  final IBreederRepository _breederRepository;

  LitterDeclarationViewModel({
    required ILitterRepository litterRepository,
    required IBreederRepository breederRepository,
  }) : _litterRepository = litterRepository,
       _breederRepository = breederRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Breeder> _mothers = [];
  List<Breeder> get mothers => _mothers;

  List<Breeder> _fathers = [];
  List<Breeder> get fathers => _fathers;

  Future<void> loadBreedersForDeclaration() async {
    _isLoading = true;
    notifyListeners();

    try {
      final all = await _breederRepository.getBreeders();
      _mothers = all
          .where((b) => b.sex == 'female' && b.status == 'active')
          .toList();
      _fathers = all
          .where((b) => b.sex == 'male' && b.status == 'active')
          .toList();
    } catch (_) {
      // Ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Litter?> declareLitter({
    required int motherId,
    int? fatherId,
    String? externalSireName,
    String? externalSireId,
    required DateTime birthDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // If there is already an active litter, mark it as inactive (only 1 active litter in this simple flow)
      final currentActive = await _litterRepository.getActiveLitter();
      if (currentActive != null) {
        currentActive.isActive = false;
        await _litterRepository.updateLitter(currentActive);
      }

      final newLitter = Litter(
        motherId: motherId,
        fatherId: fatherId,
        externalSireName: externalSireName?.trim().isEmpty ?? true
            ? null
            : externalSireName!.trim(),
        externalSireId: externalSireId?.trim().isEmpty ?? true
            ? null
            : externalSireId!.trim(),
        birthDate: birthDate,
        kennelId: 1, // Default mock kennel
        isActive: true,
      );

      final created = await _litterRepository.createLitter(newLitter);
      return created;
    } catch (_) {
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
