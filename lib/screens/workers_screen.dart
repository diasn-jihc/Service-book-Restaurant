import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/workers_bloc.dart';
import '../models/worker.dart';
import '../utils/actions.dart';
import '../widgets/app_card.dart';

class WorkersScreen extends StatelessWidget {
  const WorkersScreen({super.key});

  Future<void> _remove(BuildContext context, Worker worker) async {
    final ok = await askConfirm(
      context,
      title: 'Удалить рабочего?',
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

    workers.sort((a, b) {
      final byRole = a.role.index.compareTo(b.role.index);
      return byRole != 0 ? byRole : a.fullName.compareTo(b.fullName);
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Всего рабочих: ${workers.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final worker in workers) ...[
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
          label: const Text('Добавить рабочего'),
        ),
      ],
    );
  }
}
