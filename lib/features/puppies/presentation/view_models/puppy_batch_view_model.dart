import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../domain/repositories/i_puppy_repository.dart';

class PuppyBatchItem {
  String name;
  String sex; // 'female' | 'male'
  String color;
  double birthWeight;

  PuppyBatchItem({
    required this.name,
    required this.sex,
    required this.color,
    required this.birthWeight,
  });
}

class PuppyBatchViewModel extends ChangeNotifier {
  final IPuppyRepository _puppyRepository;

  PuppyBatchViewModel({required IPuppyRepository puppyRepository})
    : _puppyRepository = puppyRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<PuppyBatchItem> _items = [];
  List<PuppyBatchItem> get items => _items;

  void loadLitterPuppies(List<Puppy> existingPuppies) {
    if (existingPuppies.isNotEmpty) {
      _items = existingPuppies.map((p) {
        return PuppyBatchItem(
          name: p.name,
          sex: p.sex,
          color: p.color ?? '',
          birthWeight: p.birthWeight ?? 0.0,
        );
      }).toList();
    } else {
      // Default pre-fill with 3 items
      _items = [
        PuppyBatchItem(
          name: 'Chiot 1',
          sex: 'female',
          color: 'Fauve',
          birthWeight: 350.0,
        ),
        PuppyBatchItem(
          name: 'Chiot 2',
          sex: 'male',
          color: 'Fauve',
          birthWeight: 370.0,
        ),
        PuppyBatchItem(
          name: 'Chiot 3',
          sex: 'female',
          color: 'Sable',
          birthWeight: 330.0,
        ),
      ];
    }
    notifyListeners();
  }

  void addItem() {
    final nextNum = _items.length + 1;
    _items.add(
      PuppyBatchItem(
        name: 'Chiot $nextNum',
        sex: 'female',
        color: 'Fauve',
        birthWeight: 350.0,
      ),
    );
    notifyListeners();
  }

  void removeItem(int index) {
    if (_items.length > 1) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void updateSex(int index, String sex) {
    _items[index].sex = sex;
    notifyListeners();
  }

  Future<bool> saveBatch(int litterId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final puppiesToSave = _items.map((item) {
        return Puppy(
          litterId: litterId,
          name: item.name.trim().isEmpty ? 'Chiot' : item.name.trim(),
          sex: item.sex,
          color: item.color.trim().isEmpty ? null : item.color.trim(),
          status: 'available',
          birthWeight: item.birthWeight,
        );
      }).toList();

      // In a real application we would clear existing puppies of the litter or update them
      // For this mock step, we just replace all puppies of the litter in our mock DB
      // We can simulate batch creation
      await _puppyRepository.createPuppiesBatch(puppiesToSave);
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
