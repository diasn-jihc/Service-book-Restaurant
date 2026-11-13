import 'package:flutter/foundation.dart';

/// Название приложения — меняется в одном месте.
const appName = 'Столик';

/// Demo records are included in debug builds only. A release build can opt in
/// explicitly with `--dart-define=SERVICE_BOOK_DEMO=true`.
const kSeedDemoData = bool.fromEnvironment(
  'SERVICE_BOOK_DEMO',
  defaultValue: kDebugMode,
);

/// Пароль всех демо-аккаунтов.
const demoPassword = 'demo123';
