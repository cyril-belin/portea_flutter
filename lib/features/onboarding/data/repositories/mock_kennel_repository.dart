import 'package:portea_client/portea_client.dart';
import '../../domain/repositories/i_kennel_repository.dart';

class MockKennelRepository implements IKennelRepository {
  Kennel? _kennel;

  /// When non-null, the next repository call throws this. Useful for view
  /// model error-path tests. The flag is consumed on the first call and reset
  /// to null, so only the next single call fails.
  Object? throwOnNext;

  Future<void> _maybeThrow() async {
    final pending = throwOnNext;
    if (pending != null) {
      throwOnNext = null;
      throw pending;
    }
  }

  @override
  Future<Kennel?> getKennel() async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 200));
    return _kennel;
  }

  @override
  Future<Kennel> createKennel(Kennel kennel) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 200));
    _kennel = kennel;
    return kennel;
  }

  @override
  Future<void> updateKennel(Kennel kennel) async {
    await _maybeThrow();
    await Future.delayed(const Duration(milliseconds: 200));
    _kennel = kennel;
  }
}
