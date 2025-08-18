import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
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
        'Supabase keys missing. Pass --dart-define SUPABASE_URL & SUPABASE_ANON_KEY',
      );
    }
    await Supabase.initialize(url: _url, anonKey: _anon);
    _inited = true;
  }

  /// fileOrBytes: File (mobile/desktop) | Uint8List | List<int> (web)
  /// returns: public URL
  static Future<String> upload({
    required String bucket,
    required String path, // e.g. images/ts_filename.jpg
    required dynamic fileOrBytes, // File | Uint8List | List<int>
    String? contentType, // e.g. image/jpeg
  }) async {
    await ensureInitialized();
    final storage = client.storage.from(bucket);

    // İçerik türü tahmini
    contentType ??= _guessContentType(path);

    try {
      if (kIsWeb) {
        // Kesin Uint8List’e çevir
        late final Uint8List data;
        if (fileOrBytes is Uint8List) {
          data = fileOrBytes;
        } else if (fileOrBytes is List<int>) {
          data = Uint8List.fromList(fileOrBytes);
        } else {
          throw ArgumentError(
            'On web, fileOrBytes must be Uint8List or List<int>',
          );
        }

        await storage.uploadBinary(
          path,
          data,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );
      } else {
        if (fileOrBytes is! File) {
          throw ArgumentError('On mobile/desktop, fileOrBytes must be File');
        }
        await storage.upload(
          path,
          fileOrBytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );
      }
    } on StorageException catch (e) {
      // Hata mesajını doğrudan uygulamada göstermek için fırlat
      throw Exception('StorageException ${e.statusCode}: ${e.message}');
    }

    // Public bucket ise direkt public URL
    return storage.getPublicUrl(path);
  }

  static String _guessContentType(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }
}
