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

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final entries = context.watch<JournalBloc>().state.entries;
    final shown =
        entries.where((e) => _filter == null || e.category == _filter).toList();

    return Column(
      children: [
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
              ? const Center(child: Text('Записей пока нет'))
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
