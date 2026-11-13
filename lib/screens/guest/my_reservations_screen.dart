import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/data_cubit.dart';
import '../../data/app_repository.dart';
import '../../models/food_order.dart';
import '../../models/dining_table.dart';
import '../../models/reservation.dart';
import '../../utils/actions.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_title.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/status_chip.dart';
import 'restaurant_detail_screen.dart';

/// Вкладка «Мои брони»: предстоящие и история, отмена, отзыв.
class MyReservationsScreen extends StatelessWidget {
  const MyReservationsScreen({super.key});

  Future<void> _cancel(BuildContext context, Reservation r) async {
    final ok = await askConfirm(
      context,
      title: 'Отменить бронь?',
      text: 'Стол снова станет доступен другим гостям.',
      yesLabel: 'Отменить бронь',
    );
    if (!ok || !context.mounted) return;
    await context.data.run((repo) => repo.cancelReservation(r.id));
    if (context.mounted) showMessage(context, 'Бронь отменена');
  }

  Future<void> _review(BuildContext context, Reservation r) async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    var stars = 5;
    final textCtrl = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Ваш отзыв'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StarPicker(
                value: stars,
                onChanged: (v) => setLocal(() => stars = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Как всё прошло? (необязательно)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Отправить'),
            ),
          ],
        ),
      ),
    );
    final text = textCtrl.text.trim();
    textCtrl.dispose();
    if (send != true || !context.mounted) return;

    final error = await context.data.run(
      (repo) => repo.addReview(
        reservation: r,
        user: user,
        stars: stars,
        text: text,
      ),
    );
    if (!context.mounted) return;
    showMessage(context, error ?? 'Спасибо за отзыв!');
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return const SizedBox.shrink();

    final all = repo.reservationsOfUser(user.id);
    if (all.isEmpty) {
      return const EmptyState(
        icon: Icons.event_seat_outlined,
        text: 'У вас пока нет броней.\n'
            'Откройте вкладку «Рестораны» и забронируйте стол.',
      );
    }

    final now = DateTime.now();
    final upcoming = all
        .where((r) => r.status.isActive && r.end.isAfter(now))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final history = all.where((r) => !upcoming.contains(r)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (upcoming.isNotEmpty) ...[
          const SectionTitle('Предстоящие'),
          for (final r in upcoming) ...[
            _ReservationCard(
              reservation: r,
              repo: repo,
              onCancel: () => _cancel(context, r),
              onReview: () => _review(context, r),
            ),
            const SizedBox(height: 12),
          ],
        ],
        if (history.isNotEmpty) ...[
          const SectionTitle('История'),
          for (final r in history) ...[
            _ReservationCard(
              reservation: r,
              repo: repo,
              onCancel: () => _cancel(context, r),
              onReview: () => _review(context, r),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.repo,
    required this.onCancel,
    required this.onReview,
  });

  final Reservation reservation;
  final AppRepository repo;
  final VoidCallback onCancel;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final restaurant = repo.restaurantById(r.restaurantId);
    final table = repo.tableById(r.tableId);
    final order = repo.orderOfReservation(r.id);
    final canCancel = r.start.isAfter(DateTime.now()) &&
        (r.status == ReservationStatus.pending ||
            r.status == ReservationStatus.confirmed);
    final canReview =
        r.status == ReservationStatus.completed && !repo.hasReview(r.id);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  restaurant?.name ?? 'Ресторан',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              StatusChip(label: r.status.title, color: r.status.color),
            ],
          ),
          const SizedBox(height: 10),
          _Line(Icons.event,
              '${dayLabel(r.start)}, ${timeFormat.format(r.start)} – '
              '${timeFormat.format(r.end)}'),
          _Line(
            Icons.table_restaurant,
            table == null
                ? 'Стол удалён'
                : 'Стол №${table.number} · ${table.zone.title}',
          ),
          _Line(Icons.groups, '${r.guests} гост.'),
          if (r.comment.isNotEmpty) _Line(Icons.edit_note, r.comment),
          if (order != null && order.status != OrderStatus.cancelled) ...[
            const Divider(height: 22),
            Text('Заказ заранее · ${money(order.total)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            for (final item in order.items)
              Text('${item.name} × ${item.qty}',
                  style: const TextStyle(color: Colors.white70)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (canCancel)
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10)),
                  child: const Text('Отменить'),
                ),
              if (canReview)
                FilledButton.icon(
                  onPressed: onReview,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10)),
                  icon: const Icon(Icons.star_rounded),
                  label: const Text('Оставить отзыв'),
                ),
              if (restaurant != null)
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          RestaurantDetailScreen(restaurantId: restaurant.id),
                    ),
                  ),
                  child: const Text('О ресторане'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
