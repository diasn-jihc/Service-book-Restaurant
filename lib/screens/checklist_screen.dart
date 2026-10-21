import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/checklist_bloc.dart';
import '../models/checklist_item.dart';
import '../utils/actions.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _ChecklistSection(
          title: 'Открытие смены',
          icon: Icons.wb_sunny,
          type: ChecklistType.opening,
        ),
        const SizedBox(height: 16),
        const _ChecklistSection(
          title: 'Закрытие смены',
          icon: Icons.nightlight_round,
          type: ChecklistType.closing,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await askConfirm(
              context,
              title: 'Сбросить отметки?',
              text: 'Все пункты снова станут невыполненными.',
              yesLabel: 'Сбросить',
            );
            if (ok && context.mounted) {
              context.read<ChecklistBloc>().add(ChecklistReset());
            }
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('Сбросить все отметки'),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Отметки сбрасываются автоматически каждый день',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _ChecklistSection extends StatelessWidget {
  const _ChecklistSection({
    required this.title,
    required this.icon,
    required this.type,
  });

  final String title;
  final IconData icon;
  final ChecklistType type;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ChecklistBloc>().state;
    final items = state.itemsOf(type);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Text('${state.doneCount(type)} / ${items.length}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: LinearProgressIndicator(
              value: state.progress(type),
              minHeight: 6,
              backgroundColor: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          for (final item in items)
            CheckboxListTile(
              value: item.done,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                item.title,
                style: item.done
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
              subtitle: item.done
                  ? Text('${item.doneBy} • ${timeFormat.format(item.doneAt!)}')
                  : null,
              onChanged: (_) {
                final user = context.read<AuthBloc>().state.user;
                context.read<ChecklistBloc>().add(
                      ChecklistItemToggled(
                          item.id, user?.fullName ?? 'Сотрудник'),
                    );
              },
            ),
        ],
      ),
    );
  }
}
