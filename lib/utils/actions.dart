import 'package:flutter/material.dart';

import '../models/service_entry.dart';
import '../screens/add_entry_screen.dart';
import '../screens/add_worker_screen.dart';
import '../screens/entry_detail_screen.dart';

/// Короткое сообщение внизу экрана.
void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Диалог «Вы уверены?». Возвращает true, если нажали подтверждение.
Future<bool> askConfirm(
  BuildContext context, {
  required String title,
  required String text,
  String yesLabel = 'Удалить',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(yesLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> openAddEntry(BuildContext context) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const AddEntryScreen()),
  );
}

Future<void> openAddWorker(BuildContext context) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const AddWorkerScreen()),
  );
}

Future<void> openEntry(BuildContext context, ServiceEntry entry) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => EntryDetailScreen(entry: entry)),
  );
}
