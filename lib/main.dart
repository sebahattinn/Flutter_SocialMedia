import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'index.dart';
import 'services/supabase_service.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Supabase
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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Firebase Bağlantısı Tamam ✅',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeShell()),
                );
              },
              child: const Text('Indexi aç bakalım'),
            ),
          ],
        ),
      ),
    );
  }
}
