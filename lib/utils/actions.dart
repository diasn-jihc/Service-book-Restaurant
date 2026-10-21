import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/journal_bloc.dart';
import '../blocs/workers_bloc.dart';
import '../models/service_entry.dart';
import '../models/worker.dart';
import '../screens/add_entry_screen.dart';
import '../screens/add_worker_screen.dart';
import '../screens/entry_detail_screen.dart';

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

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
  final entry = await Navigator.of(context).push<ServiceEntry>(
    MaterialPageRoute(builder: (_) => const AddEntryScreen()),
  );
  if (entry == null || !context.mounted) return;

  context.read<JournalBloc>().add(EntryAdded(entry));
  showMessage(context, 'Запись добавлена');
}

Future<void> openAddWorker(BuildContext context) async {
  final worker = await Navigator.of(context).push<Worker>(
    MaterialPageRoute(builder: (_) => const AddWorkerScreen()),
  );
  if (worker == null || !context.mounted) return;

  context.read<WorkersBloc>().add(WorkerAdded(worker));
  showMessage(context, 'Рабочий добавлен: ${worker.fullName}');
}

void openEntry(BuildContext context, ServiceEntry entry) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry)),
  );
}
