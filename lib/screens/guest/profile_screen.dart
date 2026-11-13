import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/city_cubit.dart';
import '../../constants.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../utils/actions.dart';
import '../../widgets/accent_picker.dart';
import '../../widgets/app_card.dart';
import '../../widgets/city_picker.dart';
import '../../widgets/section_title.dart';

/// Профиль гостя: данные, город, цвет интерфейса, выход.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _chooseCity(BuildContext context) async {
    final cubit = context.read<CityCubit>();
    final city = await pickCity(context, cubit.state);
    if (city != null) cubit.select(city);
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

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final city = context.watch<CityCubit>().state;
    final accent = Theme.of(context).colorScheme.primary;
    if (user == null) return const SizedBox.shrink();

    final initial = user.name.isEmpty ? '?' : user.name[0].toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        AppCard(
          gradient: accentGradient(accent),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white24,
                child: Text(
                  initial,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(user.phone),
                    Text(user.role.title,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Город'),
        AppCard(
          onTap: () => _chooseCity(context),
          child: Row(
            children: [
              const Icon(Icons.location_city),
              const SizedBox(width: 12),
              Expanded(child: Text(city)),
              const Text('Изменить'),
            ],
          ),
        ),
        const SectionTitle('Цвет интерфейса'),
        const AppCard(child: AccentPicker()),
        const SectionTitle('О приложении'),
        const AppCard(
          child: Text(
            '$appName — найдите ресторан в своём городе, выберите свободный '
            'стол или кабинку, забронируйте его и закажите блюда заранее. '
            'Рестораны видят вашу бронь и готовятся к вашему приходу.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Выйти из аккаунта'),
        ),
      ],
    );
  }
}
