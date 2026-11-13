import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../models/user.dart';
import '../../utils/actions.dart';
import '../../widgets/accent_picker.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_title.dart';
import 'checklist_screen.dart';
import 'journal_screen.dart';
import 'menu_manage_screen.dart';
import 'report_screen.dart';
import 'restaurant_profile_screen.dart';
import 'staff_list_screen.dart';

/// Вкладка «Ещё»: разделы по ролям, цвет приложения и выход.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.restaurantId});

  final String restaurantId;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await askConfirm(
      context,
      title: 'Выйти из аккаунта?',
      text: 'Чтобы войти снова, понадобятся номер телефона и пароль.',
      yesLabel: 'Выйти',
    );
    if (ok && context.mounted) {
      context.read<AuthBloc>().add(LoggedOut());
    }
  }

  Widget _tile(BuildContext context, IconData icon, String title,
      String subtitle, Widget page) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => _open(context, page),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return const SizedBox.shrink();
    final role = user.role;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        AppCard(
          child: Row(
            children: [
              CircleAvatar(radius: 26, child: Icon(role.icon)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('${role.title} · ${user.phone}',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Разделы'),
        _tile(context, Icons.restaurant_menu, 'Меню',
            role.canEditMenu ? 'Блюда, цены и стоп-лист' : 'Блюда и цены',
            MenuManageScreen(restaurantId: restaurantId)),
        _tile(context, Icons.menu_book, 'Журнал обслуживания',
            'Уборка, поломки, закупки', JournalScreen(restaurantId: restaurantId)),
        if (role.canServe)
          _tile(context, Icons.checklist, 'Чек-листы',
              'Открытие и закрытие смены',
              ChecklistPage(restaurantId: restaurantId)),
        _tile(context, Icons.groups, 'Сотрудники',
            role.canManage ? 'Добавить и удалить сотрудников' : 'Список команды',
            StaffListScreen(restaurantId: restaurantId)),
        if (role.canManage) ...[
          _tile(context, Icons.storefront, 'Профиль ресторана',
              'Название, фото, часы работы',
              RestaurantProfileScreen(restaurantId: restaurantId)),
          _tile(context, Icons.bar_chart, 'Отчёт за день',
              'Выручка и заказы по официантам',
              ReportScreen(restaurantId: restaurantId)),
        ],
        const SectionTitle('Цвет приложения'),
        const AppCard(child: AccentPicker()),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Выйти'),
        ),
      ],
    );
  }
}
