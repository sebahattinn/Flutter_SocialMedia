import 'package:flutter/foundation.dart';

/// Uygulama genelinde "şu an oynayan video" bilgisini taşır.
/// PostCard'lar bunu dinleyip kendilerini pause eder.
class VideoCoordinator {
  VideoCoordinator._();

  /// Şu an oynayan postId (yoksa null)
  static final ValueNotifier<String?> current = ValueNotifier<String?>(null);

  static void requestPlay(String id) {
    if (current.value == id) return;
    current.value = id;
  }

  static void stopIfCurrent(String id) {
    if (current.value == id) current.value = null;
  }
}
