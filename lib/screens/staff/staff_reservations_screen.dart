import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/data_cubit.dart';
import '../../data/app_repository.dart';
import '../../models/food_order.dart';
import '../../models/dining_table.dart';
import '../../models/reservation.dart';
import '../../models/user.dart';
import '../../utils/actions.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';

/// Брони гостей: подтвердить, отклонить, «гости пришли».
class StaffReservationsScreen extends StatefulWidget {
  const StaffReservationsScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  State<StaffReservationsScreen> createState() =>
      _StaffReservationsScreenState();
}

class _StaffReservationsScreenState extends State<StaffReservationsScreen> {
  int _filter = 0; // 0 — ожидают, 1 — предстоящие, 2 — история

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final user = context.read<AuthBloc>().state.user;
    final role = user?.role ?? UserRole.cook;

    final now = DateTime.now();
    final all = repo.reservationsOf(widget.restaurantId);
    final pending =
        all.where((r) => r.status == ReservationStatus.pending).toList();
    final upcoming =
        all.where((r) => r.status.isActive && r.end.isAfter(now)).toList();
    final history = all
        .where((r) => !(r.status.isActive && r.end.isAfter(now)))
        .toList()
        .reversed
        .toList();

    final list = _filter == 0 ? pending : (_filter == 1 ? upcoming : history);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ChoiceChip(
                label: Text('Ожидают (${pending.length})'),
                selected: _filter == 0,
                onSelected: (_) => setState(() => _filter = 0),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Предстоящие (${upcoming.length})'),
                selected: _filter == 1,
                onSelected: (_) => setState(() => _filter = 1),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('История'),
                selected: _filter == 2,
                onSelected: (_) => setState(() => _filter = 2),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? EmptyState(
                  icon: Icons.event_busy,
                  text: _filter == 0
                      ? 'Новых заявок нет'
                      : 'Здесь пока пусто',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _ReservationCard(
                    reservation: list[i],
                    repo: repo,
                    role: role,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.repo,
    required this.role,
  });

  final Reservation reservation;
  final AppRepository repo;
  final UserRole role;

  Future<void> _confirm(BuildContext context) async {
    await context.data.run((r) => r.confirmReservation(reservation.id));
    if (context.mounted) showMessage(context, 'Бронь подтверждена');
  }

  Future<void> _cancel(BuildContext context) async {
    final ok = await askConfirm(
      context,
      title: 'Отменить бронь?',
      text: 'Гость ${reservation.guestName} увидит, что бронь отменена.',
      yesLabel: 'Отменить бронь',
    );
    if (!ok || !context.mounted) return;
    await context.data.run((r) => r.cancelReservation(reservation.id));
    if (context.mounted) showMessage(context, 'Бронь отменена');
  }

  Future<void> _arrived(BuildContext context) async {
    final error =
        await context.data.run((r) => r.seatReservation(reservation.id));
    if (!context.mounted) return;
    showMessage(context, error ?? 'Гости посажены за стол');
  }

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final table = repo.tableById(r.tableId);
    final order = repo.orderOfReservation(r.id);
    final showOrder = order != null && order.status != OrderStatus.cancelled;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${dayLabel(r.start)}, ${timeFormat.format(r.start)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              StatusChip(label: r.status.title, color: r.status.color),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(child: Text('${r.guestName} · ${r.phone}')),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.table_restaurant,
                  size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Text(table == null
                  ? 'Стол удалён'
                  : 'Стол №${table.number} · ${table.zone.title} · '
                      '${r.guests} гост.'),
            ],
          ),
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.edit_note, size: 18, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(child: Text(r.comment)),
              ],
            ),
          ],
          if (showOrder) ...[
            const Divider(height: 22),
            Text('Заказ заранее · ${money(order.total)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            for (final item in order.items)
              Text('${item.name} × ${item.qty}',
                  style: const TextStyle(color: Colors.white70)),
          ],
          if (role.canServe) ...[
            const SizedBox(height: 12),
            if (r.status == ReservationStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _confirm(context),
                      child: const Text('Подтвердить'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancel(context),
                      child: const Text('Отклонить'),
                    ),
                  ),
                ],
              ),
            if (r.status == ReservationStatus.confirmed)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _arrived(context),
                      icon: const Icon(Icons.chair),
                      label: const Text('Гости пришли'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => _cancel(context),
                    child: const Text('Отменить'),
                  ),
                ],
              ),
            if (r.status == ReservationStatus.seated)
              const Text(
                'Гости за столом. После оплаты освободите стол на вкладке «Столы».',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ],
      ),
    );
  }
}
