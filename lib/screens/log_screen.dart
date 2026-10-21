import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/journal_bloc.dart';
import '../models/service_entry.dart';
import '../widgets/entry_tile.dart';
import 'entry_detail_screen.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  EntryCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<JournalBloc>().state.entries;
    final items = entries
        .where((e) => _filter == null || e.category == _filter)
        .toList();

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
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final c in EntryCategory.values) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(c.title),
                  selected: _filter == c,
                  onSelected: (_) => setState(() => _filter = c),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Записей нет'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final entry = items[i];
                    return Dismissible(
                      key: ValueKey(entry.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        context.read<JournalBloc>().add(EntryRemoved(entry.id));
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(content: Text('Запись удалена')),
                          );
                      },
                      child: EntryTile(
                        entry: entry,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EntryDetailScreen(entry: entry),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
