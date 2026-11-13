import 'package:flutter/material.dart';

import '../../blocs/data_cubit.dart';
import '../../utils/formatters.dart';
import '../../widgets/dish_picker.dart';

/// Выбор блюд заранее. Результат — карта {id блюда: количество}.
class PreOrderScreen extends StatefulWidget {
  const PreOrderScreen({
    super.key,
    required this.restaurantId,
    required this.initial,
  });

  final String restaurantId;
  final Map<String, int> initial;

  @override
  State<PreOrderScreen> createState() => _PreOrderScreenState();
}

class _PreOrderScreenState extends State<PreOrderScreen> {
  late Map<String, int> _quantities;

  @override
  void initState() {
    super.initState();
    _quantities = Map<String, int>.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final dishes = repo.dishesOf(widget.restaurantId);

    var total = 0;
    var count = 0;
    _quantities.forEach((id, qty) {
      final dish = repo.dishById(id);
      if (dish != null) {
        total += dish.price * qty;
        count += qty;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Заказ заранее')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Блюда будут готовиться к вашему приходу. '
              'Оплата в ресторане.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          DishPicker(
            dishes: dishes,
            quantities: _quantities,
            onChanged: (q) => setState(() => _quantities = q),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(_quantities),
            child: Text(
              count == 0
                  ? 'Без предзаказа'
                  : 'Готово: $count шт. · ${money(total)}',
            ),
          ),
        ),
      ),
    );
  }
}
