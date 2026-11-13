import 'package:flutter/material.dart';

import '../../blocs/data_cubit.dart';
import '../../models/service_entry.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';
import '../../theme/app_theme.dart';
import 'add_entry_screen.dart';
import 'entry_detail_screen.dart';

/// Журнал обслуживания: уборка, поломки, закупки, санитария.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  EntryCategory? _category;

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final all = repo.entriesOf(widget.restaurantId);
    final list =
        _category == null ? all : all.where((e) => e.category == _category).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Журнал обслуживания')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddEntryScreen(restaurantId: widget.restaurantId),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Запись'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Все'),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                for (final c in EntryCategory.values) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: Icon(c.icon, size: 16),
                    label: Text(c.title),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const EmptyState(
                    icon: Icons.menu_book, text: 'Записей пока нет')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final e = list[i];
                      return AppCard(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EntryDetailScreen(entryId: e.id),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(child: Icon(e.category.icon)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${e.workerName} · ${dateTimeFormat.format(e.date)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(
                              label: e.resolved ? 'Готово' : 'Открыто',
                              color: e.resolved ? freeColor : busyColor,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
