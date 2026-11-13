import 'package:flutter/material.dart';

const _starColor = Color(0xFFFFC53D);

/// Показывает рейтинг звёздами (только чтение).
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : (rating >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded),
            size: size,
            color: _starColor,
          ),
      ],
    );
  }
}

/// Выбор оценки нажатием на звёзды.
class StarPicker extends StatelessWidget {
  const StarPicker({super.key, required this.value, required this.onChanged});

  final int value;
  final void Function(int stars) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            iconSize: 38,
            onPressed: () => onChanged(i),
            icon: Icon(
              i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _starColor,
            ),
          ),
      ],
    );
  }
}
