const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

/// URL проекта Supabase (Settings → API → Project URL).
const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');

/// anon public key (Settings → API → anon public).
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);

/// true, если заданы оба параметра Supabase.
bool get useSupabase =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
