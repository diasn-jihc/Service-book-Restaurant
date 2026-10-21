# Сервисная книжка для ресторана

## Как поставить в свой проект `service_book`
1. Удалите старую папку `lib` (там старый `providers/`) и скопируйте новую `lib` из архива.
2. Замените `pubspec.yaml` на файл из архива (или добавьте зависимости: flutter_bloc, shared_preferences, http, path_provider, intl, flutter_localizations).
3. Удалите `test/widget_test.dart` (он от старого шаблона и не компилируется).
4. Выполните:
```
flutter pub get
flutter run
```

## Какие темы курса использованы
- Раздел 2: StatefulWidget, setState, обновление интерфейса (`journal_screen`, `worker_form`).
- Раздел 3: ListView, Row, Column, прокрутка (все экраны).
- Раздел 4: классы, enum, `late`, null safety (`models/`, `late final` в формах).
- Раздел 5: переходы между экранами, передача данных и возврат результата (`utils/actions.dart`, `add_entry_screen`).
- Разделы 6-7: счётчик (`GuestsCubit` — «Гостей в зале»).
- Раздел 8: HTTP, JSON, модели (`api_client.dart`, `models/meal.dart`).
- Раздел 10: SharedPreferences, форма, список (`storage_service.dart`), запись текстового файла (`file_service.dart`).
- Раздел 11: даты и локализация (`utils/formatters.dart`, ru).
- Раздел 12: BLoC и события, смена цвета интерфейса (`blocs/`, `theme_bloc.dart`).
