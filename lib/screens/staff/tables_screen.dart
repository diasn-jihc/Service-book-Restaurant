import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/data_cubit.dart';
import '../../models/dining_table.dart';
import '../../models/food_order.dart';
import '../../models/reservation.dart';
import '../../models/user.dart';
import '../../utils/actions.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/field_decoration.dart';
import '../../widgets/section_title.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/table_tile.dart';
import 'order_edit_screen.dart';

/// Карта зала: какие столы свободны, забронированы и заняты.
class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key, required this.restaurantId});

  final String restaurantId;

  String _caption(BuildContext context, DiningTable table, TableStatus status) {
    final repo = context.repo;
    switch (status) {
      case TableStatus.free:
        return 'Свободен';
      case TableStatus.reserved:
        final next = repo.nextReservationOf(table.id);
        return next == null ? 'Забронирован' : 'Бронь ${timeFormat.format(next.start)}';
      case TableStatus.occupied:
        final since = table.since;
        final minutes =
            since == null ? 0 : DateTime.now().difference(since).inMinutes;
        return '${table.guests} гост. · $minutes мин';
    }
  }

  void _openSheet(BuildContext context, String tableId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TableSheet(tableId: tableId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final tables = repo.tablesOf(restaurantId);

    if (tables.isEmpty) {
      return const EmptyState(
        icon: Icons.table_restaurant,
        text: 'Столов пока нет.\nАдминистратор может добавить стол кнопкой «Стол».',
      );
    }

    final free = repo.tablesCount(restaurantId, TableStatus.free);
    final reserved = repo.tablesCount(restaurantId, TableStatus.reserved);
    final busy = repo.tablesCount(restaurantId, TableStatus.occupied);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Count('$free', 'Свободно', tableStatusColor(TableStatus.free)),
              _Count('$reserved', 'Бронь',
                  tableStatusColor(TableStatus.reserved)),
              _Count('$busy', 'Занято', tableStatusColor(TableStatus.occupied)),
              _Count('${repo.guestsNow(restaurantId)}', 'Гостей', Colors.white),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const TableLegend(),
        for (final zone in TableZone.values)
          if (tables.any((t) => t.zone == zone)) ...[
            SectionTitle(zone.plural),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final t in tables.where((t) => t.zone == zone))
                  TableTile(
                    table: t,
                    status: repo.statusOf(t),
                    caption: _caption(context, t, repo.statusOf(t)),
                    onTap: () => _openSheet(context, t.id),
                  ),
              ],
            ),
          ],
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// Окно «сколько гостей». Возвращает число или null.
Future<int?> askGuests(
  BuildContext context, {
  required int max,
  required int initial,
}) {
  var value = initial.clamp(1, max);
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: const Text('Сколько гостей?'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: value > 1 ? () => setLocal(() => value--) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 60,
              child: Text('$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
            ),
            IconButton.filled(
              onPressed: value < max ? () => setLocal(() => value++) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(value),
            child: const Text('Посадить'),
          ),
        ],
      ),
    ),
  );
}

/// Действия со столом: посадить, освободить, заказ, брони, настройки.
class _TableSheet extends StatelessWidget {
  const _TableSheet({required this.tableId});

  final String tableId;

  Future<void> _seat(BuildContext context, DiningTable table) async {
    final navigator = Navigator.of(context);
    final guests = await askGuests(context, max: table.seats, initial: 2);
    if (guests == null || !context.mounted) return;
    final error = await context.data.run((r) => r.seatTable(table.id, guests));
    if (!context.mounted) return;
    if (error != null) {
      showMessage(context, error);
    } else {
      navigator.pop();
    }
  }

  Future<void> _free(BuildContext context, DiningTable table) async {
    final navigator = Navigator.of(context);
    final error = await context.data.run((r) => r.freeTable(table.id));
    if (!context.mounted) return;
    if (error != null) {
      showMessage(context, error);
    } else {
      navigator.pop();
    }
  }

  Future<void> _arrived(BuildContext context, Reservation r) async {
    final navigator = Navigator.of(context);
    final error = await context.data.run((repo) => repo.seatReservation(r.id));
    if (!context.mounted) return;
    if (error != null) {
      showMessage(context, error);
    } else {
      navigator.pop();
    }
  }

  Future<void> _delete(BuildContext context, DiningTable table) async {
    final ok = await askConfirm(
      context,
      title: 'Удалить стол №${table.number}?',
      text: 'Это действие нельзя отменить.',
    );
    if (!ok || !context.mounted) return;
    final navigator = Navigator.of(context);
    final error = await context.data.run((r) => r.deleteTable(table.id));
    if (!context.mounted) return;
    if (error != null) {
      showMessage(context, error);
    } else {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final table = repo.tableById(tableId);
    if (table == null) {
      return const SizedBox(
        height: 140,
        child: Center(child: Text('Стол удалён')),
      );
    }

    final user = context.read<AuthBloc>().state.user;
    final role = user?.role ?? UserRole.cook;
    final status = repo.statusOf(table);
    final color = tableStatusColor(status);

    final now = DateTime.now();
    final openOrders = repo.orders.where((o) {
      if (o.tableId != tableId || !o.status.isOpen) return false;
      final rid = o.reservationId;
      if (rid == null) return true;
      return repo.reservationById(rid)?.status == ReservationStatus.seated;
    }).toList();
    final upcoming = repo.reservations
        .where((r) =>
            r.tableId == tableId &&
            (r.status == ReservationStatus.pending ||
                r.status == ReservationStatus.confirmed) &&
            r.end.isAfter(now))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(table.zone.icon, color: color, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Стол №${table.number}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text('${table.zone.title} · ${table.seats} мест',
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                StatusChip(label: status.title, color: color),
              ],
            ),
            if (table.occupied) ...[
              const SizedBox(height: 10),
              Text(
                'Гостей: ${table.guests}'
                '${table.since == null ? '' : ' · с ${timeFormat.format(table.since!)}'}',
              ),
            ],
            if (openOrders.isNotEmpty) ...[
              const SectionTitle('Заказы стола'),
              for (final o in openOrders)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.items.map((i) => '${i.name} ×${i.qty}').join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(label: o.status.title, color: o.status.color),
                      ],
                    ),
                  ),
                ),
            ],
            if (upcoming.isNotEmpty) ...[
              const SectionTitle('Брони стола'),
              for (final r in upcoming)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${dayLabel(r.start)}, ${timeFormat.format(r.start)}'
                                ' · ${r.guestName}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              Text('${r.guests} гост. · ${r.phone}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                        ),
                        if (role.canServe &&
                            !table.occupied &&
                            r.status == ReservationStatus.confirmed)
                          TextButton(
                            onPressed: () => _arrived(context, r),
                            child: const Text('Пришли'),
                          )
                        else
                          StatusChip(
                              label: r.status.title, color: r.status.color),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            if (role.canServe) ...[
              if (table.occupied) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderEditScreen(
                            restaurantId: table.restaurantId,
                            tableId: table.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Новый заказ'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _free(context, table),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Освободить стол'),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _seat(context, table),
                    icon: const Icon(Icons.chair),
                    label: const Text('Посадить гостей'),
                  ),
                ),
            ],
            if (role.canManage) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showTableForm(context,
                          restaurantId: table.restaurantId, table: table);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Изменить'),
                  ),
                  TextButton.icon(
                    onPressed: () => _delete(context, table),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Удалить'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Форма стола: номер, места и зона (зал / кабинка / терраса).
Future<void> showTableForm(
  BuildContext context, {
  required String restaurantId,
  DiningTable? table,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TableForm(restaurantId: restaurantId, table: table),
  );
}

class _TableForm extends StatefulWidget {
  const _TableForm({required this.restaurantId, this.table});

  final String restaurantId;
  final DiningTable? table;

  @override
  State<_TableForm> createState() => _TableFormState();
}

class _TableFormState extends State<_TableForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberCtrl;
  late final TextEditingController _seatsCtrl;
  late TableZone _zone;

  @override
  void initState() {
    super.initState();
    final t = widget.table;
    final repo = context.data.repo;
    final nextNumber = repo.tablesOf(widget.restaurantId).length + 1;
    _numberCtrl = TextEditingController(text: '${t?.number ?? nextNumber}');
    _seatsCtrl = TextEditingController(text: '${t?.seats ?? 4}');
    _zone = t?.zone ?? TableZone.hall;
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final number = int.parse(_numberCtrl.text.trim());
    final seats = int.parse(_seatsCtrl.text.trim());
    final existing = widget.table;
    final navigator = Navigator.of(context);

    final error = await context.data.run((r) {
      if (existing == null) {
        return r.addTable(
          restaurantId: widget.restaurantId,
          number: number,
          seats: seats,
          zone: _zone,
        );
      }
      return r.updateTable(
        tableId: existing.id,
        number: number,
        seats: seats,
        zone: _zone,
      );
    });
    if (!mounted) return;
    if (error != null) {
      showMessage(context, error);
    } else {
      navigator.pop();
    }
  }

  String? _validateNumber(String? v, int min, int max, String what) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n < min || n > max) return '$what: от $min до $max';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.table != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(editing ? 'Изменить стол' : 'Новый стол',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _numberCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: fieldDecoration('Номер стола', Icons.tag),
                      validator: (v) => _validateNumber(v, 1, 999, 'Номер'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _seatsCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: fieldDecoration('Мест', Icons.event_seat),
                      validator: (v) => _validateNumber(v, 1, 30, 'Мест'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Зона'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final z in TableZone.values)
                    ChoiceChip(
                      avatar: Icon(z.icon, size: 18),
                      label: Text(z.title),
                      selected: _zone == z,
                      onSelected: (_) => setState(() => _zone = z),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(editing ? 'Сохранить' : 'Добавить стол'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
