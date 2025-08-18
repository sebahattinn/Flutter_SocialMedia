import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'index.dart'; // HomeShell burada tanımlı olmalı

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Social Media App',
      theme: ThemeData.dark(),
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
              "Firebase Bağlantısı Tamam ✅",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    // Butona tıklandığında HomeShell sayfasına geçiş
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeShell(),
                      ),
                    );
                  },
                  child: const Text('Indexi aç bakalm'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
