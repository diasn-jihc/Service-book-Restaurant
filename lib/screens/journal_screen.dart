import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/journal_bloc.dart';
import '../models/service_entry.dart';
import '../utils/actions.dart';
import '../widgets/entry_tile.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  EntryCategory? _filter;
  String _query = '';
  bool? _resolvedFilter;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final entries = context.watch<JournalBloc>().state.entries;
    final query = _query.trim().toLowerCase();
    final shown = entries.where((entry) {
      final matchesCategory = _filter == null || entry.category == _filter;
      final matchesStatus =
          _resolvedFilter == null || entry.resolved == _resolvedFilter;
      final matchesQuery = query.isEmpty ||
          entry.title.toLowerCase().contains(query) ||
          entry.description.toLowerCase().contains(query) ||
          entry.workerName.toLowerCase().contains(query);
      return matchesCategory && matchesStatus && matchesQuery;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Поиск по записям и сотрудникам',
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Очистить поиск',
                      onPressed: () => setState(() => _query = ''),
                      icon: const Icon(Icons.clear),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              for (final option in <(String, bool?)>[
                ('Все статусы', null),
                ('Открытые', false),
                ('Решённые', true),
              ]) ...[
                if (option != ('Все статусы', null)) const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(option.$1),
                  selected: _resolvedFilter == option.$2,
                  selectedColor: accent,
                  onSelected: (_) =>
                      setState(() => _resolvedFilter = option.$2),
                ),
              ],
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Все'),
                selected: _filter == null,
                selectedColor: accent,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final c in EntryCategory.values) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: Icon(c.icon, size: 18),
                  label: Text(c.title),
                  selected: _filter == c,
                  selectedColor: accent,
                  onSelected: (_) => setState(() => _filter = c),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Text(entries.isEmpty
                      ? 'Записей пока нет'
                      : 'По выбранным фильтрам ничего не найдено'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = shown[index];
                    return Dismissible(
                      key: ValueKey(entry.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => askConfirm(
                        context,
                        title: 'Удалить запись?',
                        text: entry.title,
                      ),
                      onDismissed: (_) => context
                          .read<JournalBloc>()
                          .add(EntryRemoved(entry.id)),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete),
                      ),
                      child: EntryTile(
                        entry: entry,
                        onTap: () => openEntry(context, entry),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
