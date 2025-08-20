import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_media_app/state/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _username = TextEditingController();
  final _name = TextEditingController();

  void _showSnack(String msg, {bool isError = false}) {
    final snack = SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snack);
  }

  Future<void> _onSubmit() async {
    final email = _email.text.trim();
    final pass = _pass.text;
    final username = _username.text.trim();
    final fullName = _name.text.trim();

    debugPrint(
      '[RegisterPage] Submit tapped email=$email username=$username fullName=$fullName',
    );

    if (email.isEmpty || pass.isEmpty) {
      _showSnack('Email ve şifre zorunlu', isError: true);
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .register(
          email: email,
          password: pass,
          username: username.isEmpty ? null : username,
          fullName: fullName.isEmpty ? null : fullName,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    // build içinde dinle: önemli state geçişleri için log + snackbar
    ref.listen(authControllerProvider, (prev, next) {
      if (next.error != null &&
          next.error!.isNotEmpty &&
          next.error != prev?.error) {
        debugPrint('[RegisterPage] ERROR: ${next.error}');
        _showSnack(next.error!, isError: true);
      }

      if ((prev?.loading ?? false) && !next.loading && next.error == null) {
        // Kayıt bitti (başarılı) ama session yoksa muhtemelen email confirm açık
        if (next.session == null) {
          debugPrint(
            '[RegisterPage] Register done but session is null (email confirmation likely ON).',
          );
          _showSnack('Kayıt isteği alındı. E-postanı doğrulaman gerekebilir.');
        } else {
          debugPrint(
            '[RegisterPage] Register success and session present. AuthGate will navigate.',
          );
          _showSnack('Kayıt başarılı!');
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pass,
              decoration: const InputDecoration(labelText: 'Şifre'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Kullanıcı adı'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
            const SizedBox(height: 16),

            if (auth.error != null && auth.error!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  auth.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            ElevatedButton(
              onPressed: auth.loading ? null : _onSubmit,
              child: auth.loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kayıt Ol'),
            ),

            const SizedBox(height: 16),
            // Mini debug panel (ekrandan da takip etmek istersen)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DefaultTextStyle(
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DEBUG'),
                      Text('loading = ${auth.loading}'),
                      Text('session = ${auth.session != null}'),
                      Text('error   = ${auth.error ?? "-"}'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
