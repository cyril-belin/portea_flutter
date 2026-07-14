import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../domain/repositories/i_puppy_repository.dart';
import '../../domain/repositories/i_care_repository.dart';

class AddCareViewModel extends ChangeNotifier {
  final IPuppyRepository _puppyRepository;
  final ICareRepository _careRepository;

  AddCareViewModel({
    required IPuppyRepository puppyRepository,
    required ICareRepository careRepository,
  }) : _puppyRepository = puppyRepository,
       _careRepository = careRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> saveCareEntry({
    required String type, // 'vaccine' | 'deworming' | 'other'
    required String product,
    required DateTime date,
    int? puppyId,
    int? litterId,
    bool targetAllLitter = false,
    DateTime? reminderDate,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (targetAllLitter && litterId != null) {
        // Find all puppies in the litter and add care entries for each
        final puppies = await _puppyRepository.getPuppies(litterId);

        // Also save a main litter care entry
        final groupEntry = CareEntry(
          type: type,
          product: product,
          appliedAt: date,
          litterId: litterId,
          reminderAt: reminderDate,
          notes: notes,
        );
        await _careRepository.addCareEntry(groupEntry);

        for (final p in puppies) {
          final puppyEntry = CareEntry(
            type: type,
            product: product,
            appliedAt: date,
            puppyId: p.id!,
            reminderAt: reminderDate,
            notes: notes,
          );
          await _careRepository.addCareEntry(puppyEntry);
        }
      } else {
        // Individual care entry
        final entry = CareEntry(
          type: type,
          product: product,
          appliedAt: date,
          puppyId: puppyId,
          litterId: litterId,
          reminderAt: reminderDate,
          notes: notes,
        );
        await _careRepository.addCareEntry(entry);
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
