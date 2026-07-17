import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../domain/repositories/i_weighing_repository.dart';

class GroupWeighingItem {
  final int puppyId;
  final String name;
  final double? lastWeight;
  double? newWeight;

  GroupWeighingItem({
    required this.puppyId,
    required this.name,
    this.lastWeight,
    this.newWeight,
  });
}

class GroupWeighingViewModel extends ChangeNotifier {
  final IWeighingRepository _weighingRepository;

  GroupWeighingViewModel({
    required IWeighingRepository weighingRepository,
  }) : _weighingRepository = weighingRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<GroupWeighingItem> _items = [];
  List<GroupWeighingItem> get items => _items;

  DateTime _weighedAt = DateTime.now();
  DateTime get weighedAt => _weighedAt;
  set weighedAt(DateTime val) {
    _weighedAt = val;
    notifyListeners();
  }

  /// Loads the litter's puppies with their most recent weight in a single
  /// repository call (anti-N+1, review claim 3.5). A puppy that has never been
  /// weighed falls back to its birth weight.
  Future<void> loadLitterPuppies(int litterId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final rows = await _weighingRepository.getPuppiesWithLastWeighing(
        litterId,
      );
      _items = [
        for (final r in rows)
          GroupWeighingItem(
            puppyId: r.puppy.id!,
            name: r.puppy.name,
            lastWeight: r.lastWeighing?.weightGrams ?? r.puppy.birthWeight,
          ),
      ];
    } catch (_) {
      // Ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateWeight(int index, double? weight) {
    _items[index].newWeight = weight;
  }

  /// Persists one weighing per item with a positive, non-null entered weight.
  /// Empty cells are ignored (rule 4 of the F05 spec — only weighed puppies
  /// produce an entry). A single batched call carries them all; the server
  /// validates and applies them transactionally.
  Future<bool> saveWeighingSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final entries = <WeighingEntry>[];
      for (final item in _items) {
        if (item.newWeight != null && item.newWeight! > 0) {
          entries.add(
            WeighingEntry(
              puppyId: item.puppyId,
              weighedAt: _weighedAt,
              weightGrams: item.newWeight!,
            ),
          );
        }
      }
      if (entries.isNotEmpty) {
        await _weighingRepository.addWeighings(entries);
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
