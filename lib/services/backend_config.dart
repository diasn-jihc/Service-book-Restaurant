import 'package:flutter/foundation.dart';

/// Build-time connection settings. Never put a Supabase service-role key here.
class BackendConfig {
  const BackendConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static void validate() {
    final hasUrl = supabaseUrl.isNotEmpty;
    final hasKey = supabasePublishableKey.isNotEmpty;
    if (hasUrl != hasKey) {
      throw StateError(
        'Provide both SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY with '
        '--dart-define, or leave both unset for local demo mode.',
      );
    }
  }

  static const demoDataEnabled = bool.fromEnvironment(
    'SERVICE_BOOK_DEMO',
    defaultValue: kDebugMode,
  );
}
