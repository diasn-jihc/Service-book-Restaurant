import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/data_cubit.dart';
import '../../models/checklist_item.dart';
import '../../models/user.dart';
import '../../utils/actions.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_title.dart';

/// Чек-листы открытия и закрытия. Отметки действуют только сегодня.
class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key, required this.restaurantId});

  final String restaurantId;

  Future<void> _reset(BuildContext context) async {
    final ok = await askConfirm(
      context,
      title: 'Сбросить отметки?',
      text: 'Все пункты снова станут невыполненными.',
      yesLabel: 'Сбросить',
    );
    if (!ok || !context.mounted) return;
    await context.data.run((r) => r.resetChecklist(restaurantId));
  }

  Widget _group(BuildContext context, String title, IconData icon,
      List<ChecklistItem> items, String workerName) {
    final done = items.where((i) => i.doneToday).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          '$title · $done из ${items.length}',
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: items.isEmpty ? 0 : done / items.length,
                minHeight: 4,
              ),
              for (final item in items)
                CheckboxListTile(
                  value: item.doneToday,
                  title: Text(item.title),
                  subtitle: item.doneToday && item.doneAt != null
                      ? Text('${item.doneBy ?? ''} · ${timeFormat.format(item.doneAt!)}',
                          style: const TextStyle(fontSize: 12))
                      : null,
                  secondary: Icon(icon, size: 20),
                  onChanged: (_) => context.data
                      .run((r) => r.toggleChecklistItem(item.id, workerName)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final user = context.read<AuthBloc>().state.user;
    final name = user?.name ?? '';
    final opening = repo.checklistOf(restaurantId, ChecklistType.opening);
    final closing = repo.checklistOf(restaurantId, ChecklistType.closing);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        _group(context, 'Открытие смены', Icons.wb_sunny_outlined, opening, name),
        _group(context, 'Закрытие смены', Icons.nightlight_outlined, closing, name),
        if (user != null && user.role.canManage) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _reset(context),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Сбросить все отметки'),
          ),
        ],
      ],
    );
  }
}

/// Тот же чек-лист, но отдельным экраном со стрелкой «назад».
class ChecklistPage extends StatelessWidget {
  const ChecklistPage({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Чек-листы')),
      body: ChecklistScreen(restaurantId: restaurantId),
    );
  }
}
