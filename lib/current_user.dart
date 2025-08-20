import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dev_fake_auth.dart';

final currentUidProvider = Provider<String?>((ref) {
  final sb = Supabase.instance.client;
  final real = sb.auth.currentUser?.id;
  return kDevNoAuth ? kDevMyUid : real;
});
