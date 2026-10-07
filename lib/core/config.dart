const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

/// URL проекта Supabase (Settings → API → Project URL).
/// Значения по умолчанию — для GitHub Pages (anon/publishable ключ публичный).
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://lvhxxcnczoksocyfxfpg.supabase.co',
);

/// anon / publishable key (Settings → API Keys).
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_ZjgnHbav2MOjzGXrMzPubw_9c1SDjqC',
);

/// true, если заданы оба параметра Supabase.
bool get useSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
