import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../domain/repositories/i_puppy_repository.dart';
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
  final IPuppyRepository _puppyRepository;
  final IWeighingRepository _weighingRepository;

  GroupWeighingViewModel({
    required IPuppyRepository puppyRepository,
    required IWeighingRepository weighingRepository,
  }) : _puppyRepository = puppyRepository,
       _weighingRepository = weighingRepository;

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

  Future<void> loadLitterPuppies(int litterId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final puppies = await _puppyRepository.getPuppies(litterId);
      final itemsList = <GroupWeighingItem>[];
      for (final p in puppies) {
        final weighings = await _weighingRepository.getWeighings(p.id!);
        final last = weighings.isNotEmpty
            ? weighings.last.weightGrams
            : p.birthWeight;
        itemsList.add(
          GroupWeighingItem(
            puppyId: p.id!,
            name: p.name,
            lastWeight: last,
          ),
        );
      }
      _items = itemsList;
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
