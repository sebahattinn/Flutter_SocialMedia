import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:postgrest/postgrest.dart';

import '../services/auth_service.dart';
import 'auth_state.dart';

void _logC(String msg) => debugPrint('[AuthController] $msg');

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final svc = ref.read(authServiceProvider);
    return AuthController(svc);
  },
);

class AuthController extends StateNotifier<AuthState> {
  final AuthService _svc;
  StreamSubscription<Session?>? _sub;

  AuthController(this._svc) : super(const AuthState()) {
    final curr = Supabase.instance.client.auth.currentSession;
    _logC('constructor: currentSession=${curr != null} user=${curr?.user.id}');
    state = state.copy(session: curr);

    _sub = _svc.onAuthState().listen((session) {
      _logC(
        'onAuthState -> session=${session != null} user=${session?.user.id}',
      );
      state = state.copy(session: session, loading: false, error: null);
    });
  }

  Future<void> login(String email, String password) async {
    _logC('login(email=$email) START');
    state = state.copy(loading: true, error: null);
    try {
      await _svc.signInWithEmail(email: email, password: password);
      _logC('login DONE');
      state = state.copy(loading: false);
    } on AuthException catch (e, st) {
      _logC('login AuthException: ${e.message}');
      debugPrint(st.toString());
      state = state.copy(loading: false, error: e.message);
    } catch (e, st) {
      _logC('login Unknown error: $e');
      debugPrint(st.toString());
      state = state.copy(loading: false, error: e.toString());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? username,
    String? fullName,
  }) async {
    _logC(
      'register(email=$email, username=$username, fullName=$fullName) START',
    );
    state = state.copy(loading: true, error: null);
    try {
      await _svc.signUpWithEmail(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
      );
      _logC('register DONE (check confirmation/session via onAuthState)');
      state = state.copy(loading: false);
    } on AuthException catch (e, st) {
      _logC(
        'register AuthException: code=${e.statusCode} message=${e.message}',
      );
      debugPrint(st.toString());
      state = state.copy(loading: false, error: e.message);
    } on PostgrestException catch (e, st) {
      _logC('register PostgrestException: code=${e.code} message=${e.message}');
      debugPrint(st.toString());
      state = state.copy(loading: false, error: e.message);
    } catch (e, st) {
      _logC('register Unknown error: $e');
      debugPrint(st.toString());
      state = state.copy(loading: false, error: e.toString());
    }
  }

  Future<void> resendConfirm(String email) {
    _logC('resendConfirm(email=$email)');
    return _svc.resendConfirmationEmail(email);
  }

  Future<void> resetPassword(String email) {
    _logC('resetPassword(email=$email)');
    return _svc.resetPasswordEmail(email);
  }

  Future<void> logout() {
    _logC('logout()');
    return _svc.signOut();
  }

  @override
  void dispose() {
    _logC('dispose()');
    _sub?.cancel();
    super.dispose();
  }
}
