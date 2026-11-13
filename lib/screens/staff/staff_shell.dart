import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/data_cubit.dart';
import '../../models/food_order.dart';
import '../../models/reservation.dart';
import '../../models/user.dart';
import 'checklist_screen.dart';
import 'more_screen.dart';
import 'orders_screen.dart';
import 'staff_dashboard_screen.dart';
import 'staff_reservations_screen.dart';
import 'tables_screen.dart';

class _TabInfo {
  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
  final int badge;

  const _TabInfo(
    this.id,
    this.label,
    this.icon,
    this.selectedIcon,
    this.page, {
    this.badge = 0,
  });
}

/// Кабинет сотрудника. Набор вкладок зависит от роли:
/// администратор, шеф и официант видят зал, а повар и бармен — кухню.
class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final repo = context.repo;
    final rid = user?.restaurantId;
    final restaurant = rid == null ? null : repo.restaurantById(rid);

    if (user == null || rid == null || restaurant == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront, size: 56, color: Colors.white38),
                const SizedBox(height: 12),
                const Text('Ресторан этого аккаунта не найден'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.read<AuthBloc>().add(LoggedOut()),
                  child: const Text('Выйти'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final role = user.role;
    final pendingReservations = repo
        .reservationsOf(rid)
        .where((r) => r.status == ReservationStatus.pending)
        .length;
    final freshOrders = repo
        .staffOrdersOf(rid)
        .where((o) => o.status == OrderStatus.fresh)
        .length;

    final tabs = <_TabInfo>[];
    void go(String id) {
      final index = tabs.indexWhere((t) => t.id == id);
      if (index != -1) setState(() => _tab = index);
    }

    if (role.canServe) {
      tabs.addAll([
        _TabInfo('dashboard', 'Сводка', Icons.dashboard_outlined,
            Icons.dashboard,
            StaffDashboardScreen(restaurantId: rid, onNavigate: go)),
        _TabInfo('tables', 'Столы', Icons.table_restaurant_outlined,
            Icons.table_restaurant, TablesScreen(restaurantId: rid)),
        _TabInfo('reservations', 'Брони', Icons.event_available_outlined,
            Icons.event_available,
            StaffReservationsScreen(restaurantId: rid),
            badge: pendingReservations),
        _TabInfo('orders', 'Заказы', Icons.receipt_long_outlined,
            Icons.receipt_long, OrdersScreen(restaurantId: rid),
            badge: freshOrders),
      ]);
    } else {
      // Повар и бармен: кухня и чек-листы.
      tabs.addAll([
        _TabInfo('orders', 'Кухня', Icons.soup_kitchen_outlined,
            Icons.soup_kitchen, OrdersScreen(restaurantId: rid),
            badge: freshOrders),
        _TabInfo('checklists', 'Чек-листы', Icons.checklist_outlined,
            Icons.checklist, ChecklistScreen(restaurantId: rid)),
      ]);
    }
    tabs.add(_TabInfo('more', 'Ещё', Icons.menu, Icons.menu_open,
        MoreScreen(restaurantId: rid)));

    final index = _tab < tabs.length ? _tab : 0;
    final current = tabs[index];

    Widget? fab;
    if (current.id == 'tables' && role.canManage) {
      fab = FloatingActionButton.extended(
        onPressed: () => showTableForm(context, restaurantId: rid),
        icon: const Icon(Icons.add),
        label: const Text('Стол'),
      );
    } else if (current.id == 'orders' && role.canServe) {
      fab = FloatingActionButton.extended(
        onPressed: () => startNewOrder(context, rid),
        icon: const Icon(Icons.add),
        label: const Text('Заказ'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(current.label),
            Text(
              '${restaurant.name} · ${role.title}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: index,
        children: [for (final t in tabs) t.page],
      ),
      floatingActionButton: fab,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          for (final t in tabs)
            NavigationDestination(
              icon: Badge(
                isLabelVisible: t.badge > 0,
                label: Text('${t.badge}'),
                child: Icon(t.icon),
              ),
              selectedIcon: Badge(
                isLabelVisible: t.badge > 0,
                label: Text('${t.badge}'),
                child: Icon(t.selectedIcon),
              ),
              label: t.label,
            ),
        ],
      ),
    );
  }
}
