import 'package:flutter/material.dart';
import 'package:portea_client/portea_client.dart';
import '../../domain/repositories/i_breeder_repository.dart';

class BreederListViewModel extends ChangeNotifier {
  final IBreederRepository _breederRepository;

  BreederListViewModel({required IBreederRepository breederRepository})
    : _breederRepository = breederRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Breeder> _breeders = [];
  List<Breeder> get breeders => _breeders;

  Future<void> loadBreeders() async {
    _isLoading = true;
    notifyListeners();

    try {
      _breeders = await _breederRepository.getBreeders();
    } catch (_) {
      // Quietly ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
