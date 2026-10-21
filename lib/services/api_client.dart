import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal.dart';
import '../models/service_entry.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
}

class ApiClient {
  ApiClient({http.Client? client, Uri? syncEndpoint})
      : _client = client ?? http.Client(),
        _syncEndpoint = syncEndpoint;

  final http.Client _client;
  final Uri? _syncEndpoint;

  static const _configuredSyncUrl =
      String.fromEnvironment('SERVICE_BOOK_SYNC_URL');

  static const _mealUrl = 'https://www.themealdb.com/api/json/v1/1/random.php';

  Future<void> uploadEntries(List<ServiceEntry> entries) async {
    final endpoint = _syncEndpoint ??
        (_configuredSyncUrl.isEmpty ? null : Uri.tryParse(_configuredSyncUrl));
    if (endpoint == null || !endpoint.hasScheme || endpoint.host.isEmpty) {
      throw ApiException(
        'Синхронизация не настроена. Укажите SERVICE_BOOK_SYNC_URL для сервера приложения.',
      );
    }
    final response = await _client
        .post(
          endpoint,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body:
              jsonEncode({'entries': entries.map((e) => e.toJson()).toList()}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Ошибка сервера: ${response.statusCode}');
    }
  }

  Future<Meal> fetchRandomMeal() async {
    final response = await _client
        .get(Uri.parse(_mealUrl))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw ApiException('Ошибка сервера: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final meals = data['meals'] as List<dynamic>?;
    if (meals == null || meals.isEmpty) {
      throw ApiException('Блюдо не найдено');
    }
    return Meal.fromJson(meals.first as Map<String, dynamic>);
  }
}
