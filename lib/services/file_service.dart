import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/service_entry.dart';
import '../models/worker.dart';
import '../utils/formatters.dart';

class FileService {
  Future<String?> saveReport(String text) async {
    if (kIsWeb) return null;

    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final file = File('${dir.path}/service_book_$stamp.txt');
    await file.writeAsString(text);
    return file.path;
  }
}

String buildReport(List<ServiceEntry> entries, List<Worker> workers) {
  final b = StringBuffer();
  b.writeln('СЕРВИСНАЯ КНИЖКА РЕСТОРАНА');
  b.writeln('Создан: ${dateTimeFormat.format(DateTime.now())}');
  b.writeln();

  b.writeln('Рабочие (${workers.length}):');
  for (final w in workers) {
    b.writeln('- ${w.fullName}, ${w.role.title}, ${w.phone}');
  }
  b.writeln();

  b.writeln('Записи журнала (${entries.length}):');
  final resolvedCount = entries.where((entry) => entry.resolved).length;
  b.writeln('Решено: $resolvedCount');
  b.writeln('Требуют внимания: ${entries.length - resolvedCount}');
  for (final e in entries) {
    final status = e.resolved ? 'решено' : 'требует внимания';
    b.writeln('- ${dateTimeFormat.format(e.date)} | ${e.category.title} | '
        '${e.title} | ${e.workerName} (${e.workerRole.title}) | $status');
    if (e.description.isNotEmpty) b.writeln('    ${e.description}');
  }
  return b.toString();
}
