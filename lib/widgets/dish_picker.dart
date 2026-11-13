import 'package:flutter/material.dart';

import '../models/dish.dart';
import '../utils/formatters.dart';
import 'app_card.dart';
import 'section_title.dart';

/// Список блюд с кнопками «+/−». Используется для предзаказа гостя
/// и для заказа официанта. Количество хранится в карте {id блюда: штук}.
class DishPicker extends StatelessWidget {
  const DishPicker({
    super.key,
    required this.dishes,
    required this.quantities,
    required this.onChanged,
  });

  final List<Dish> dishes;
  final Map<String, int> quantities;
  final void Function(Map<String, int> quantities) onChanged;

  void _change(Dish dish, int delta) {
    final copy = Map<String, int>.from(quantities);
    final next = (copy[dish.id] ?? 0) + delta;
    if (next <= 0) {
      copy.remove(dish.id);
    } else {
      copy[dish.id] = next;
    }
    onChanged(copy);
  }

  @override
  Widget build(BuildContext context) {
    if (dishes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('В меню пока нет блюд')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in DishCategory.values)
          ..._section(context, category),
      ],
    );
  }

  List<Widget> _section(BuildContext context, DishCategory category) {
    final items = dishes.where((d) => d.category == category).toList();
    if (items.isEmpty) return [];

    return [
      SectionTitle(category.title),
      for (final dish in items) ...[
        _DishRow(
          dish: dish,
          qty: quantities[dish.id] ?? 0,
          onMinus: () => _change(dish, -1),
          onPlus: () => _change(dish, 1),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }
}

class _DishRow extends StatelessWidget {
  const _DishRow({
    required this.dish,
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  final Dish dish;
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final off = !dish.available;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Opacity(
              opacity: off ? 0.45 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dish.name,
                      style: Theme.of(context).textTheme.titleSmall),
                  if (dish.description.isNotEmpty)
                    Text(dish.description,
                        style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    off ? 'Нет в наличии' : money(dish.price),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          if (!off) ...[
            if (qty > 0) ...[
              IconButton.filledTonal(
                onPressed: onMinus,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 30,
                child: Text('$qty',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
            IconButton.filled(
              onPressed: onPlus,
              icon: const Icon(Icons.add),
            ),
          ],
        ],
      ),
    );
  }
}
