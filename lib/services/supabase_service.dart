import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'URL_SUPABASE_KAMU',
      anonKey: 'PUBLISHABLE_KEY_KAMU',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
