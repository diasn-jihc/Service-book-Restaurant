import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/data_cubit.dart';
import '../../data/app_repository.dart';
import '../../models/dining_table.dart';
import '../../models/food_order.dart';
import '../../theme/app_theme.dart';
import '../../utils/actions.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/field_decoration.dart';
import '../../widgets/section_title.dart';
import '../../widgets/table_tile.dart';
import 'preorder_screen.dart';

/// Бронь стола: дата → время → гости → стол → (предзаказ) → подтверждение.
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late DateTime _day;
  DateTime? _slot;
  int _guests = 2;
  String? _tableId;
  TableZone? _zone; // фильтр по зоне, null — все
  Map<String, int> _preorder = {};
  late final TextEditingController _commentCtrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
    _commentCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _editPreorder() async {
    final result = await Navigator.of(context).push<Map<String, int>>(
      MaterialPageRoute(
        builder: (_) => PreOrderScreen(
          restaurantId: widget.restaurantId,
          initial: _preorder,
        ),
      ),
    );
    if (result != null) setState(() => _preorder = result);
  }

  Future<void> _submit() async {
    final user = context.read<AuthBloc>().state.user;
    final dataCubit = context.data;
    final repo = dataCubit.repo;
    final restaurant = repo.restaurantById(widget.restaurantId);
    final slot = _slot;
    final tableId = _tableId;
    if (user == null || restaurant == null || slot == null || tableId == null) {
      return;
    }

    final items = <OrderItem>[];
    _preorder.forEach((id, qty) {
      final dish = repo.dishById(id);
      if (dish != null && dish.available) {
        items.add(OrderItem(
          dishId: dish.id,
          name: dish.name,
          price: dish.price,
          qty: qty,
        ));
      }
    });

    setState(() => _busy = true);
    final error = await dataCubit.run(
      (r) => r.createReservation(
        restaurant: restaurant,
        tableId: tableId,
        user: user,
        start: slot,
        guests: _guests,
        comment: _commentCtrl.text.trim(),
        items: items,
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      showMessage(context, error);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: freeColor, size: 48),
        title: const Text('Заявка отправлена'),
        content: Text(
          '${restaurant.name}\n'
          '${dayLabel(slot)}, ${timeFormat.format(slot)} · $_guests гост.\n\n'
          'Ресторан подтвердит бронь. Статус смотрите во вкладке «Мои брони».',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отлично'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final restaurant = repo.restaurantById(widget.restaurantId);
    if (restaurant == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.storefront, text: 'Ресторан не найден'),
      );
    }

    final today = DateTime.now();
    final days = List.generate(
      14,
      (i) => DateTime(today.year, today.month, today.day + i),
    );
    final slots = repo.slotsFor(restaurant, _day);
    final allTables = repo.tablesOf(restaurant.id);
    final shownTables =
        allTables.where((t) => _zone == null || t.zone == _zone).toList();
    var maxSeats = 1;
    for (final t in allTables) {
      if (t.seats > maxSeats) maxSeats = t.seats;
    }
    final zonesHere = TableZone.values
        .where((z) => allTables.any((t) => t.zone == z))
        .toList();

    // Выбранный слот и стол действительны, только если они ещё доступны.
    final slot = (_slot != null && slots.any((s) => s.isAtSameMomentAs(_slot!)))
        ? _slot
        : null;
    DiningTable? selectedTable;
    if (slot != null && _tableId != null) {
      final t = repo.tableById(_tableId!);
      if (t != null && t.seats >= _guests && repo.isTableFree(t.id, slot)) {
        selectedTable = t;
      }
    }

    var preorderCount = 0;
    var preorderSum = 0;
    _preorder.forEach((id, qty) {
      final dish = repo.dishById(id);
      if (dish != null) {
        preorderCount += qty;
        preorderSum += dish.price * qty;
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text('Бронь · ${restaurant.name}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const SectionTitle('1. Дата'),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  ChoiceChip(
                    label: Text(i == 0
                        ? 'Сегодня'
                        : (i == 1
                            ? 'Завтра'
                            : '${weekdayFormat.format(days[i])} '
                                '${dayFormat.format(days[i])}')),
                    selected: isSameDay(days[i], _day),
                    onSelected: (_) => setState(() {
                      _day = days[i];
                      _slot = null;
                      _tableId = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SectionTitle('2. Время'),
          if (slots.isEmpty)
            const Text(
              'На этот день уже нет свободного времени. Выберите другую дату.',
              style: TextStyle(color: Colors.white70),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in slots)
                  ChoiceChip(
                    label: Text(timeFormat.format(s)),
                    selected: slot != null && s.isAtSameMomentAs(slot),
                    onSelected: (_) => setState(() => _slot = s),
                  ),
              ],
            ),
          const SectionTitle('3. Сколько гостей'),
          Row(
            children: [
              const Icon(Icons.groups),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed:
                    _guests > 1 ? () => setState(() => _guests--) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 48,
                child: Text('$_guests',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              IconButton.filled(
                onPressed: _guests < maxSeats
                    ? () => setState(() => _guests++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SectionTitle('4. Выберите стол'),
          if (zonesHere.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Все'),
                    selected: _zone == null,
                    onSelected: (_) => setState(() => _zone = null),
                  ),
                  for (final z in zonesHere)
                    ChoiceChip(
                      avatar: Icon(z.icon, size: 18),
                      label: Text(z.plural),
                      selected: _zone == z,
                      onSelected: (_) => setState(() => _zone = z),
                    ),
                ],
              ),
            ),
          const TableLegend(),
          const SizedBox(height: 12),
          if (allTables.isEmpty)
            const Text('У ресторана пока нет столов')
          else if (slot == null)
            const AppCard(
              child: Row(
                children: [
                  Icon(Icons.schedule),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Сначала выберите время, и мы покажем, '
                        'какие столы свободны.'),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final t in shownTables) _tableTile(repo, t, slot),
              ],
            ),
          const SectionTitle('5. Заказ заранее (по желанию)'),
          AppCard(
            onTap: _editPreorder,
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    preorderCount == 0
                        ? 'Выбрать блюда — они будут готовы к вашему приходу'
                        : 'Выбрано: $preorderCount шт. · ${money(preorderSum)}',
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _commentCtrl,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: fieldDecoration(
                'Пожелания к брони', Icons.edit_note,
                hint: 'Например: день рождения, детский стул'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedTable != null && slot != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Стол №${selectedTable.number} · ${selectedTable.zone.title} · '
                    '${dayLabel(slot)}, ${timeFormat.format(slot)} · $_guests гост.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (selectedTable == null || _busy) ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Забронировать'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableTile(AppRepository repo, DiningTable t, DateTime slot) {
    final free = repo.isTableFree(t.id, slot);
    if (!free) {
      return TableTile(
        table: t,
        status: TableStatus.occupied,
        caption: 'Занят в это время',
        dimmed: true,
      );
    }
    if (t.seats < _guests) {
      return TableTile(
        table: t,
        status: TableStatus.free,
        caption: 'Мало мест',
        dimmed: true,
      );
    }
    return TableTile(
      table: t,
      status: TableStatus.free,
      caption: 'Свободен',
      selected: _tableId == t.id,
      onTap: () => setState(() => _tableId = t.id),
    );
  }
}
