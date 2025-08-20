import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  final bool loading;
  final Session? session;
  final String? error;

  const AuthState({this.loading = false, this.session, this.error});

  AuthState copy({bool? loading, Session? session, String? error}) {
    return AuthState(
      loading: loading ?? this.loading,
      session: session ?? this.session,
      error: error,
    );
  }
}
