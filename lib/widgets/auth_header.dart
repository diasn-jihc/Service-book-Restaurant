import 'package:flutter/material.dart';

import '../constants.dart';
import '../theme/app_theme.dart';

/// Логотип и название на экранах входа и регистрации.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: accentGradient(accent),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(Icons.restaurant, size: 46),
        ),
        const SizedBox(height: 16),
        Text(
          appName,
          style: Theme.of(context)
              .textTheme
              .headlineLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}
