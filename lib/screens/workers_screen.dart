import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/workers_bloc.dart';
import '../models/worker.dart';
import '../utils/actions.dart';
import '../widgets/app_card.dart';
import 'edit_worker_screen.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  String _query = '';

  Future<void> _edit(BuildContext context, Worker worker) async {
    final updated = await Navigator.of(context).push<Worker>(
      MaterialPageRoute(builder: (_) => EditWorkerScreen(worker: worker)),
    );
    if (updated != null && context.mounted) {
      context.read<WorkersBloc>().add(WorkerUpdated(updated, worker.phone));
      if (updated.id == context.read<AuthBloc>().state.user?.id) {
        context.read<AuthBloc>().add(UserProfileUpdated(updated, worker.phone));
      }
    }
  }

  Future<void> _remove(BuildContext context, Worker worker) async {
    final ok = await askConfirm(
      context,
      title: 'Удалить сотрудника?',
      text: worker.fullName,
    );
    if (ok && context.mounted) {
      context.read<WorkersBloc>().add(WorkerRemoved(worker.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final workers = [...context.watch<WorkersBloc>().state.workers];
    final me = context.watch<AuthBloc>().state.user;
    final accent = Theme.of(context).colorScheme.primary;
    final query = _query.trim().toLowerCase();
    final filtered = workers.where((worker) {
      return query.isEmpty ||
          worker.fullName.toLowerCase().contains(query) ||
          worker.phone.toLowerCase().contains(query) ||
          worker.role.title.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final byRole = a.role.index.compareTo(b.role.index);
      return byRole != 0 ? byRole : a.fullName.compareTo(b.fullName);
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: [
        Text('${workers.length} сотрудников',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Поиск по имени, телефону или должности',
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Очистить поиск',
                    onPressed: () => setState(() => _query = ''),
                    icon: const Icon(Icons.clear),
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              workers.isEmpty
                  ? 'Сотрудников пока нет. Добавьте первого.'
                  : 'По запросу «${_query.trim()}» ничего не найдено.',
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final worker in filtered) ...[
            AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: accent,
                    child: Icon(worker.role.icon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.id == me?.id
                              ? '${worker.fullName} (вы)'
                              : worker.fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(worker.role.title),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 14),
                            const SizedBox(width: 4),
                            Text(worker.phone),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Изменить сотрудника',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _edit(context, worker),
                  ),
                  if (worker.id != me?.id)
                    IconButton(
                      tooltip: 'Удалить',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _remove(context, worker),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => openAddWorker(context),
          icon: const Icon(Icons.person_add),
          label: const Text('Добавить сотрудника'),
        ),
      ],
    );
  }
}
