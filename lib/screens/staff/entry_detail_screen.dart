import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/data_cubit.dart';
import '../../models/service_entry.dart';
import '../../models/user.dart';
import '../../utils/actions.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';

/// Подробности записи журнала. Удалять может только администратор.
class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({super.key, required this.entryId});

  final String entryId;

  ServiceEntry? _find(List<ServiceEntry> list) {
    for (final e in list) {
      if (e.id == entryId) return e;
    }
    return null;
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await askConfirm(
      context,
      title: 'Удалить запись?',
      text: 'Это действие нельзя отменить.',
    );
    if (!ok || !context.mounted) return;
    await context.data.run((r) => r.removeEntry(entryId));
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final user = context.read<AuthBloc>().state.user;
    final entry = _find(repo.entries);

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Запись не найдена')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Запись'),
        actions: [
          if (user != null && user.role.canManage)
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
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(entry.category.icon),
                    const SizedBox(width: 8),
                    Text(entry.category.title,
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(entry.title,
                    style: Theme.of(context).textTheme.titleLarge),
                if (entry.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(entry.description),
                ],
                const Divider(height: 28),
                Text('Автор: ${entry.workerName} · ${entry.workerRole.title}'),
                const SizedBox(height: 4),
                Text('Дата: ${dateTimeFormat.format(entry.date)}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: entry.resolved,
            onChanged: (_) =>
                context.data.run((r) => r.toggleEntryResolved(entry.id)),
            title: const Text('Вопрос решён'),
          ),
        ],
      ),
    );
  }
}
