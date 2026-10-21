import 'package:flutter/material.dart';
import '../models/service_entry.dart';
import '../utils/formatters.dart';
import 'app_card.dart';

class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, required this.onTap});

  final ServiceEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accent,
            child: Icon(entry.category.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.category.title} • ${dateTimeFormat.format(entry.date)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  entry.workerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            entry.resolved ? Icons.check_circle : Icons.error_outline,
            color: entry.resolved ? Colors.greenAccent : Colors.orangeAccent,
          ),
        ],
      ),
    );
  }
}
