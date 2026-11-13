import 'package:intl/intl.dart';

// Форматы на русском языке (локаль ru включается в main).
final dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm', 'ru');
final dayKeyFormat = DateFormat('yyyy-MM-dd');
final timeFormat = DateFormat('HH:mm', 'ru');
final shortDateFormat = DateFormat('d MMMM', 'ru');
final longDateFormat = DateFormat('d MMMM, EEEE', 'ru');
final weekdayFormat = DateFormat('E', 'ru');
final dayFormat = DateFormat('d', 'ru');
final _moneyFormat = NumberFormat.decimalPattern('ru');

/// 12500 -> «12 500 ₸»
String money(int value) =>
    '${_moneyFormat.format(value).replaceAll(' ', ' ')} ₸';

/// 600 -> «10:00»
String minutesLabel(int minutes) {
  final h = (minutes ~/ 60) % 24;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// «Сегодня», «Завтра» или «12 ноября».
String dayLabel(DateTime day) {
  final now = DateTime.now();
  if (isSameDay(day, now)) return 'Сегодня';
  if (isSameDay(day, now.add(const Duration(days: 1)))) return 'Завтра';
  return shortDateFormat.format(day);
}
