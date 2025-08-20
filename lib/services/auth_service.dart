import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

void _logS(String msg) => debugPrint('[AuthService] $msg');

class AuthService {
  SupabaseClient get _sb => SupabaseService.client;

  Stream<Session?> onAuthState() => _sb.auth.onAuthStateChange.map((e) {
    _logS(
      'onAuthStateChange: session=${e.session != null} user=${e.session?.user.id}',
    );
    return e.session;
  });

  User? get currentUser => _sb.auth.currentUser;

  Future<void> signOut() {
    _logS('signOut() called');
    return _sb.auth.signOut();
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _logS('signInWithEmail(email=$email) START');
    final res = await _sb.auth.signInWithPassword(
      email: email,
      password: password,
    );
    _logS(
      'signInWithEmail DONE -> session=${res.session != null} user=${res.user?.id}',
    );
    return res;
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? username,
    String? fullName,
  }) async {
    final redirect = kIsWeb
        ? Uri.base.origin
        : 'io.supabase.flutter://login-callback';
    _logS(
      'signUpWithEmail(email=$email, username=$username, fullName=$fullName) START, redirect=$redirect',
    );

    final res = await _sb.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: redirect,
      data: {
        if (username != null) 'username': username,
        if (fullName != null) 'full_name': fullName,
      },
    );

    _logS(
      'signUp RESULT -> session=${res.session != null}, user=${res.user?.id}',
    );

    // Email confirmation açıksa genelde burada session NULL olur.
    if (res.session == null || res.user == null) {
      _logS(
        'No session after signUp (confirmation likely ON). Skipping profile upsert.',
      );
      return res;
    }

    // Session varsa profili yaz
    try {
      _logS('Upserting profile for user=${res.user!.id}');
      final upsertRes = await _sb.from('profiles').upsert({
        'id': res.user!.id,
        'username': username,
        'full_name': fullName,
      }).select();
      _logS('Profile upsert OK -> ${upsertRes.runtimeType}');
    } on PostgrestException catch (e, st) {
      _logS(
        'Profile upsert FAILED (Postgrest) code=${e.code} message=${e.message}',
      );
      debugPrint(st.toString());
      rethrow;
    } catch (e, st) {
      _logS('Profile upsert FAILED (Unknown) $e');
      debugPrint(st.toString());
      rethrow;
    }

    _logS('signUpWithEmail DONE');
    return res;
  }

  Future<void> resendConfirmationEmail(String email) async {
    final redirect = kIsWeb
        ? Uri.base.origin
        : 'io.supabase.flutter://login-callback';
    _logS('resendConfirmationEmail(email=$email, redirect=$redirect)');
    await _sb.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: redirect,
    );
  }

  Future<void> resetPasswordEmail(String email) async {
    final redirect = kIsWeb
        ? Uri.base.origin
        : 'io.supabase.flutter://login-callback';
    _logS('resetPasswordEmail(email=$email, redirect=$redirect)');
    await _sb.auth.resetPasswordForEmail(email, redirectTo: redirect);
  }
}
