// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'services/supabase_service.dart';
import 'features/auth/auth_gate.dart'; // login/register geçişini buradan yapıyoruz
import 'index.dart'; // HomeShell burada

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Supabase init
  await SupabaseService.ensureInitialized();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseDark = ThemeData.dark();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Social Media App',
      themeMode: ThemeMode.dark,
      theme: baseDark.copyWith(
        textTheme: GoogleFonts.notoSansTextTheme(baseDark.textTheme),
      ),
      home: const AuthGate(),
      // 🔑 burada AuthGate var → login/register olmuşsa HomeShell’e yönlendirecek
    );
  }
}
