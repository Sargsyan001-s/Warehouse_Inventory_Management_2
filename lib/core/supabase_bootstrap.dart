import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';

Future<void> initSupabaseIfConfigured() async {
  if (!useSupabase) return;
  await Supabase.initialize(
    url: supabaseUrl,
    // ignore: deprecated_member_use — anon key из Settings → API
    anonKey: supabaseAnonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
