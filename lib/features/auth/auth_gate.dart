import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpod auth state
import 'package:social_media_app/state/auth_controller.dart';

// Login ekranın (dosya adın buysa)
import 'login.dart';

// App’in ana shell’i
import 'package:social_media_app/index.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    // oturum yoksa → Login
    if (auth.session == null) {
      return const LoginPage();
    }

    // oturum varsa → uygulama ana iskeleti
    return const HomeShell();
  }
}
