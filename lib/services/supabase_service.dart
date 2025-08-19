import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool _inited = false;
  static SupabaseClient get client => Supabase.instance.client;

  static final String _url = const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static final String _anon = const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static Future<void> ensureInitialized() async {
    if (_inited) return;
    if (_url.isEmpty || _anon.isEmpty) {
      throw Exception(
        'Supabase keys missing. Run with --dart-define SUPABASE_URL and SUPABASE_ANON_KEY',
      );
    }
    await Supabase.initialize(url: _url, anonKey: _anon);
    _inited = true;
  }

  // -------- helpers --------
  static String sanitizeFileName(String name) {
    final noSpaces = name.trim().replaceAll(RegExp(r'\s+'), '_');
    // sadece harf/rakam/._- kalsın
    return noSpaces.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
  }

  static String joinPath(String folder, String fileName) {
    folder = folder.replaceAll(RegExp(r'^/+|/+$'), '');
    fileName = sanitizeFileName(fileName);
    return '$folder/$fileName';
  }

  /// Unified upload for web (bytes) & mobile/desktop (File).
  /// Returns the public URL (if the bucket is public).
  static Future<String> upload({
    required String bucket,
    required String path, // e.g. 'images/uid_file.jpg' (NO leading slash)
    required dynamic fileOrBytes, // File OR Uint8List/List<int>
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
