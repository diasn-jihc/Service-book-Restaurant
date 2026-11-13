import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/data_cubit.dart';
import '../../models/reservation.dart';
import 'my_reservations_screen.dart';
import 'profile_screen.dart';
import 'restaurants_screen.dart';

/// Главный экран гостя с нижней навигацией.
class GuestShell extends StatefulWidget {
  const GuestShell({super.key});

  @override
  State<GuestShell> createState() => _GuestShellState();
}

class _GuestShellState extends State<GuestShell> {
  int _tab = 0;

  static const _titles = ['Рестораны', 'Мои брони', 'Профиль'];

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final user = context.read<AuthBloc>().state.user;
    final activeCount = user == null
        ? 0
        : repo
            .reservationsOfUser(user.id)
            .where((r) => r.status.isActive)
            .length;

    return Scaffold(
      appBar: _tab == 0 ? null : AppBar(title: Text(_titles[_tab])),
      body: IndexedStack(
        index: _tab,
        children: const [
          RestaurantsScreen(),
          MyReservationsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Рестораны',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: activeCount > 0,
              label: Text('$activeCount'),
              child: const Icon(Icons.event_seat_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: activeCount > 0,
              label: Text('$activeCount'),
              child: const Icon(Icons.event_seat),
            ),
            label: 'Мои брони',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
