import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import '../data/app_repository.dart';
import '../models/food_order.dart';
import '../utils/formatters.dart';

/// Собирает текстовый отчёт за сегодня: выручка и заказы по официантам.
String buildDayReport(AppRepository repo, String restaurantId) {
  final restaurant = repo.restaurantById(restaurantId);
  final now = DateTime.now();
  final buffer = StringBuffer();

  buffer.writeln('Отчёт за ${longDateFormat.format(now)}');
  buffer.writeln(restaurant?.name ?? '');
  buffer.writeln('');

  final paid = repo
      .ordersOf(restaurantId)
      .where((o) =>
          o.status == OrderStatus.paid &&
          o.paidAt != null &&
          isSameDay(o.paidAt!, now))
      .toList();

  final revenue = paid.fold<int>(0, (sum, o) => sum + o.total);
  buffer.writeln('Выручка: ${money(revenue)}');
  buffer.writeln('Оплаченных заказов: ${paid.length}');
  if (paid.isNotEmpty) {
    buffer.writeln('Средний чек: ${money(revenue ~/ paid.length)}');
  }
  buffer.writeln('Гостей в зале сейчас: ${repo.guestsNow(restaurantId)}');
  buffer.writeln('');

  buffer.writeln('По сотрудникам:');
  final byWorker = <String, List<FoodOrder>>{};
  for (final o in paid) {
    byWorker.putIfAbsent(o.createdByName, () => []).add(o);
  }
  if (byWorker.isEmpty) {
    buffer.writeln('  оплаченных заказов пока нет');
  }
  byWorker.forEach((name, list) {
    final sum = list.fold<int>(0, (s, o) => s + o.total);
    buffer.writeln('  $name — ${list.length} зак., ${money(sum)}');
  });

  buffer.writeln('');
  buffer.writeln('Чеки:');
  for (final o in paid) {
    buffer.writeln(
        '  ${timeFormat.format(o.paidAt!)}  ${o.createdByName}  ${money(o.total)}');
  }
  return buffer.toString();
}

/// Сохраняет отчёт в файл. Возвращает путь или null (веб-версия).
Future<String?> saveReportFile(String text) async {
  if (kIsWeb) return null;
  final dir = await getApplicationDocumentsDirectory();
  final stamp = DateTime.now().toIso8601String().substring(0, 10);
  final file = File('${dir.path}/report_$stamp.txt');
  await file.writeAsString(text);
  return file.path;
}
