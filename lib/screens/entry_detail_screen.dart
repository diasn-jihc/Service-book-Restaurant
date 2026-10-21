import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/journal_bloc.dart';
import '../models/service_entry.dart';
import '../models/worker.dart';
import '../utils/actions.dart';
import '../utils/formatters.dart';

class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({super.key, required this.entry});

  final ServiceEntry entry;

  Future<void> _delete(BuildContext context) async {
    final ok = await askConfirm(
      context,
      title: 'Удалить запись?',
      text: 'Это действие нельзя отменить.',
    );
    if (!ok || !context.mounted) return;

    context.read<JournalBloc>().add(EntryRemoved(entry.id));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JournalBloc, JournalState>(
      builder: (context, state) {
        ServiceEntry current = entry;
        for (final e in state.entries) {
          if (e.id == entry.id) current = e;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Запись'),
            actions: [
              IconButton(
                tooltip: 'Удалить',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(current.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              _InfoRow(Icons.category, 'Категория', current.category.title),
              _InfoRow(Icons.event, 'Дата', dateTimeFormat.format(current.date)),
              _InfoRow(Icons.person, 'Ответственный', current.workerName),
              _InfoRow(current.workerRole.icon, 'Роль', current.workerRole.title),
              _InfoRow(
                current.synced ? Icons.cloud_done : Icons.cloud_off,
                'Сервер',
                current.synced ? 'Отправлено' : 'Не отправлено',
              ),
              const Divider(height: 32),
              Text('Описание', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(current.description.isEmpty
                  ? 'Нет описания'
                  : current.description),
              const SizedBox(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Вопрос решён'),
                value: current.resolved,
                onChanged: (_) => context
                    .read<JournalBloc>()
                    .add(EntryResolvedToggled(current.id)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text('$label: '),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
