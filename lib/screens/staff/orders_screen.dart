import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/data_cubit.dart';
import '../../data/app_repository.dart';
import '../../models/dining_table.dart';
import '../../models/food_order.dart';
import '../../models/user.dart';
import '../../utils/actions.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';
import 'order_edit_screen.dart';

/// Кто какой статус может менять:
/// кухня и бар — «новый → готовится → готов», зал — «подан → оплачен».
bool canAdvance(UserRole role, OrderStatus status) {
  switch (status) {
    case OrderStatus.fresh:
    case OrderStatus.cooking:
      return role.canCook;
    case OrderStatus.ready:
    case OrderStatus.served:
      return role.canServe;
    case OrderStatus.paid:
    case OrderStatus.cancelled:
      return false;
  }
}

/// Выбор занятого стола и переход к созданию заказа.
Future<void> startNewOrder(BuildContext context, String restaurantId) async {
  final repo = context.data.repo;
  final occupied =
      repo.tablesOf(restaurantId).where((t) => t.occupied).toList();
  if (occupied.isEmpty) {
    showMessage(context, 'Сначала посадите гостей за стол на вкладке «Столы»');
    return;
  }

  final picked = await showModalBottomSheet<DiningTable>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Для какого стола заказ?',
                  style: Theme.of(ctx).textTheme.titleLarge),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final t in occupied)
                  ListTile(
                    leading: Icon(t.zone.icon),
                    title: Text('Стол №${t.number}'),
                    subtitle: Text('${t.zone.title} · ${t.guests} гост.'),
                    onTap: () => Navigator.of(ctx).pop(t),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  if (picked == null || !context.mounted) return;

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          OrderEditScreen(restaurantId: restaurantId, tableId: picked.id),
    ),
  );
}

/// Заказы ресторана. Для повара и бармена это экран кухни.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _filter = 0; // 0 — в работе, 1 — история

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final user = context.read<AuthBloc>().state.user;
    final role = user?.role ?? UserRole.cook;
    final kitchenOnly = !role.canServe;

    final all = repo.staffOrdersOf(widget.restaurantId);
    bool visible(OrderStatus s) => kitchenOnly
        ? (s == OrderStatus.fresh ||
            s == OrderStatus.cooking ||
            s == OrderStatus.ready)
        : s.isOpen;

    final active = all.where((o) => visible(o.status)).toList()
      ..sort((a, b) =>
          (a.forTime ?? a.createdAt).compareTo(b.forTime ?? b.createdAt));
    final history = all.where((o) => !o.status.isOpen).toList();
    final list = (kitchenOnly || _filter == 0) ? active : history;

    return Column(
      children: [
        if (!kitchenOnly)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('В работе (${active.length})'),
                  selected: _filter == 0,
                  onSelected: (_) => setState(() => _filter = 0),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('История'),
                  selected: _filter == 1,
                  onSelected: (_) => setState(() => _filter = 1),
                ),
              ],
            ),
          ),
        Expanded(
          child: list.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long,
                  text: kitchenOnly
                      ? 'Новых заказов для кухни нет'
                      : 'Заказов нет',
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, kitchenOnly ? 12 : 4, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _OrderCard(order: list[i], repo: repo, role: role),
                ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.repo,
    required this.role,
  });

  final FoodOrder order;
  final AppRepository repo;
  final UserRole role;

  Future<void> _advance(BuildContext context) async {
    await context.data.run((r) => r.advanceOrder(order.id));
  }

  Future<void> _cancel(BuildContext context) async {
    final ok = await askConfirm(
      context,
      title: 'Отменить заказ?',
      text: 'Заказ будет убран из работы.',
      yesLabel: 'Отменить заказ',
    );
    if (!ok || !context.mounted) return;
    await context.data.run((r) => r.cancelOrder(order.id));
  }

  @override
  Widget build(BuildContext context) {
    final o = order;
    final table = o.tableId == null ? null : repo.tableById(o.tableId!);
    final tableLabel = table == null ? 'Стол удалён' : 'Стол №${table.number}';
    final title = o.isPreorder
        ? 'Предзаказ к ${timeFormat.format(o.forTime ?? o.createdAt)}'
        : tableLabel;
    final next = o.status.next;
    final showNext = next != null && canAdvance(role, o.status);
    final showCancel = role.canServe && o.status.isOpen;
    final comment =
        o.comment == 'Предзаказ к брони' ? '' : o.comment;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(o.isPreorder ? Icons.event : Icons.table_restaurant,
                  size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              StatusChip(label: o.status.title, color: o.status.color),
            ],
          ),
          if (o.isPreorder)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('$tableLabel · гость ${o.createdByName}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ),
          const SizedBox(height: 10),
          for (final item in o.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Text(item.name)),
                  Text('× ${item.qty}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Комментарий: $comment',
                style: const TextStyle(color: Colors.amberAccent)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${o.createdByName} · ${timeFormat.format(o.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ),
              Text(money(o.total),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          if (showNext || showCancel) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (showNext)
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _advance(context),
                      child: Text(o.status.nextLabel),
                    ),
                  ),
                if (showNext && showCancel) const SizedBox(width: 10),
                if (showCancel)
                  OutlinedButton(
                    onPressed: () => _cancel(context),
                    child: const Text('Отмена'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
