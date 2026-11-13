import 'package:flutter/material.dart';

import '../models/dining_table.dart';
import '../theme/app_theme.dart';

Color tableStatusColor(TableStatus status) {
  switch (status) {
    case TableStatus.free:
      return freeColor;
    case TableStatus.reserved:
      return reservedColor;
    case TableStatus.occupied:
      return busyColor;
  }
}

/// Плитка стола: номер, места, зона и цвет по статусу.
class TableTile extends StatelessWidget {
  const TableTile({
    super.key,
    required this.table,
    required this.status,
    this.selected = false,
    this.dimmed = false,
    this.caption,
    this.onTap,
  });

  final DiningTable table;
  final TableStatus status;
  final bool selected;
  final bool dimmed; // недоступен для выбора
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = tableStatusColor(status);
    final accent = Theme.of(context).colorScheme.primary;

    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 104,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? accent.withAlpha(70) : color.withAlpha(35),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : color.withAlpha(170),
              width: selected ? 2.2 : 1.2,
            ),
          ),
          child: Column(
            children: [
              Icon(table.zone.icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(
                '№${table.number}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${table.zone.title} · ${table.seats} мест',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                caption ?? status.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Подсказка цветов: свободен / забронирован / занят.
class TableLegend extends StatelessWidget {
  const TableLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final s in TableStatus.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: tableStatusColor(s),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(s.title, style: const TextStyle(fontSize: 12)),
            ],
          ),
      ],
    );
  }
}
