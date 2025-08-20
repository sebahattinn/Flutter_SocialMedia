// lib/services/supabase_service.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool _inited = false;
  static SupabaseClient get client => Supabase.instance.client;

  // dart-define ile gelmezse fallback olarak sabit değerler kullanılacak
  static final String _url = const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR-PROJECT.supabase.co', // fallback sabit
  );
  static final String _anon = const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR-ANON-KEY', // fallback sabit
  );

  /// Supabase'i initialize et (PKCE auth ile mobile uyumlu)
  static Future<void> ensureInitialized() async {
    if (_inited) return;

    if (_url.isEmpty || _anon.isEmpty) {
      throw Exception(
        'Supabase keys missing. Run with --dart-define SUPABASE_URL and SUPABASE_ANON_KEY',
      );
    }

    await Supabase.initialize(
      url: _url,
      anonKey: _anon,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // mobile için ideal
      ),
    );

    _inited = true;
  }

  // -------- helpers --------
  /// Dosya adını güvenli hale getirir (sadece harf/rakam/._- bırakır)
  static String sanitizeFileName(String name) {
    final noSpaces = name.trim().replaceAll(RegExp(r'\s+'), '_');
    return noSpaces.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
  }

  /// Klasör + dosya adı birleştir
  static String joinPath(String folder, String fileName) {
    folder = folder.replaceAll(RegExp(r'^/+|/+$'), '');
    fileName = sanitizeFileName(fileName);
    return '$folder/$fileName';
  }

  /// Web (Uint8List) veya mobile/desktop (File) için unified upload.
  /// Dönen değer: public URL (bucket public ise)
  static Future<String> upload({
    required String bucket,
    required String path, // örn: 'images/uid_file.jpg' (leading slash yok)
    required dynamic fileOrBytes, // File veya Uint8List/List<int>
    String? contentType,
  }) async {
    await ensureInitialized();
    final s = client.storage.from(bucket);

    if (kIsWeb) {
      await s.uploadBinary(
        path,
        fileOrBytes,
        fileOptions: FileOptions(upsert: true, contentType: contentType),
      );
    } else {
      await s.upload(
        path,
        fileOrBytes as File,
        fileOptions: FileOptions(upsert: true, contentType: contentType),
      );
    }

    return s.getPublicUrl(path);
  }
}
