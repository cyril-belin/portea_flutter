import 'package:flutter/foundation.dart';

/// Adapts a nullable-value listenable (such as Serverpod's
/// `ValueListenable<AuthSuccess?>`) into a simple [ValueListenable<bool>]
/// that reports whether the value is non-null (i.e. the user is authenticated).
///
/// Generic over [T] so the class stays decoupled from any auth library type:
/// core never imports Serverpod's `AuthSuccess`.
class AuthenticatedListenable<T> extends ChangeNotifier
    implements ValueListenable<bool> {
  AuthenticatedListenable(this._authInfoListenable) {
    _authInfoListenable.addListener(_onChanged);
  }

  final ValueListenable<T?> _authInfoListenable;

  @override
  bool get value => _authInfoListenable.value != null;

  void _onChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _authInfoListenable.removeListener(_onChanged);
    super.dispose();
  }
}
