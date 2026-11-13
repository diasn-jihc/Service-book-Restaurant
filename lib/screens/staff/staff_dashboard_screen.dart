import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/data_cubit.dart';
import '../../models/checklist_item.dart';
import '../../models/dining_table.dart';
import '../../models/food_order.dart';
import '../../models/reservation.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_title.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_chip.dart';
import 'checklist_screen.dart';
import 'journal_screen.dart';

/// Сводка ресторана для администратора, шефа и официанта.
class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({
    super.key,
    required this.restaurantId,
    required this.onNavigate,
  });

  final String restaurantId;
  final void Function(String tabId) onNavigate;

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final user = context.read<AuthBloc>().state.user;
    final restaurant = repo.restaurantById(restaurantId);
    final accent = Theme.of(context).colorScheme.primary;
    if (user == null || restaurant == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final totalTables = repo.tablesOf(restaurantId).length;
    final freeTables = repo.tablesCount(restaurantId, TableStatus.free);
    final reservations = repo.reservationsOf(restaurantId);
    final todayCount = reservations
        .where((r) => r.status.isActive && isSameDay(r.start, now))
        .length;
    final pendingCount =
        reservations.where((r) => r.status == ReservationStatus.pending).length;
    final openOrders =
        repo.staffOrdersOf(restaurantId).where((o) => o.status.isOpen).length;
    final revenue = repo.revenueToday(restaurantId);
    final paidCount = repo.paidOrdersToday(restaurantId);
    final average = paidCount == 0 ? 0 : revenue ~/ paidCount;
    final unresolved =
        repo.entriesOf(restaurantId).where((e) => !e.resolved).length;
    final upcoming = reservations
        .where((r) => r.status.isActive && r.end.isAfter(now))
        .take(3)
        .toList();

    int done(ChecklistType type) =>
        repo.checklistOf(restaurantId, type).where((i) => i.doneToday).length;
    int total(ChecklistType type) => repo.checklistOf(restaurantId, type).length;

    void openChecklist() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChecklistPage(restaurantId: restaurantId),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        AppCard(
          gradient: accentGradient(accent),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                child: Icon(user.role.icon, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    Text('${user.name} · ${user.role.title}'),
                    Text(longDateFormat.format(now),
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 100,
          ),
          children: [
            StatCard(
              icon: Icons.table_restaurant,
              value: '$freeTables / $totalTables',
              label: 'Свободных столов',
              color: freeColor,
              onTap: () => onNavigate('tables'),
            ),
            StatCard(
              icon: Icons.groups,
              value: '${repo.guestsNow(restaurantId)}',
              label: 'Гостей сейчас',
            ),
            StatCard(
              icon: Icons.event_available,
              value: '$todayCount',
              label: 'Брони на сегодня',
              onTap: () => onNavigate('reservations'),
            ),
            StatCard(
              icon: Icons.notification_important,
              value: '$pendingCount',
              label: 'Ждут подтверждения',
              color: pendingCount > 0 ? reservedColor : null,
              onTap: () => onNavigate('reservations'),
            ),
            StatCard(
              icon: Icons.receipt_long,
              value: '$openOrders',
              label: 'Заказов в работе',
              onTap: () => onNavigate('orders'),
            ),
            StatCard(
              icon: Icons.warning_amber_rounded,
              value: '$unresolved',
              label: 'Проблем в журнале',
              color: unresolved > 0 ? busyColor : null,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JournalScreen(restaurantId: restaurantId),
                ),
              ),
            ),
            StatCard(
              icon: Icons.payments,
              value: money(revenue),
              label: 'Выручка сегодня',
            ),
            StatCard(
              icon: Icons.receipt,
              value: money(average),
              label: 'Средний чек',
            ),
          ],
        ),
        const SectionTitle('Смена'),
        _ProgressCard(
          title: 'Открытие смены',
          icon: Icons.wb_sunny,
          done: done(ChecklistType.opening),
          total: total(ChecklistType.opening),
          onTap: openChecklist,
        ),
        const SizedBox(height: 10),
        _ProgressCard(
          title: 'Закрытие смены',
          icon: Icons.nightlight_round,
          done: done(ChecklistType.closing),
          total: total(ChecklistType.closing),
          onTap: openChecklist,
        ),
        SectionTitle(
          'Ближайшие брони',
          trailing: TextButton(
            onPressed: () => onNavigate('reservations'),
            child: const Text('Все'),
          ),
        ),
        if (upcoming.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Ближайших броней нет',
                style: TextStyle(color: Colors.white70)),
          )
        else
          for (final r in upcoming) ...[
            AppCard(
              onTap: () => onNavigate('reservations'),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(timeFormat.format(r.start),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      Text(dayLabel(r.start),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.guestName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          'Стол №${repo.tableById(r.tableId)?.number ?? '?'}'
                          ' · ${r.guests} гост.',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(label: r.status.title, color: r.status.color),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.icon,
    required this.done,
    required this.total,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final int done;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Text('$done / $total'),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 8,
            backgroundColor: Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
