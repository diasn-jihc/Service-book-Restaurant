import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/theme_bloc.dart';
import '../theme/app_theme.dart';

/// Выбор цвета интерфейса кружками.
class AccentPicker extends StatelessWidget {
  const AccentPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            for (var i = 0; i < accentOptions.length; i++)
              GestureDetector(
                onTap: () => context.read<ThemeBloc>().add(AccentSelected(i)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: accentOptions[i].color,
                      child: state.accentIndex == i
                          ? const Icon(Icons.check, size: 22)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(accentOptions[i].name,
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
