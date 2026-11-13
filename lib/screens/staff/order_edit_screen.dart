import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/data_cubit.dart';
import '../../models/food_order.dart';
import '../../utils/actions.dart';
import '../../utils/formatters.dart';
import '../../widgets/dish_picker.dart';
import '../../widgets/field_decoration.dart';

/// Новый заказ за столом: официант выбирает блюда и отправляет на кухню.
class OrderEditScreen extends StatefulWidget {
  const OrderEditScreen({
    super.key,
    required this.restaurantId,
    required this.tableId,
  });

  final String restaurantId;
  final String tableId;

  @override
  State<OrderEditScreen> createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends State<OrderEditScreen> {
  Map<String, int> _quantities = {};
  late final TextEditingController _commentCtrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _commentCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = context.read<AuthBloc>().state.user;
    final dataCubit = context.data;
    final repo = dataCubit.repo;
    if (user == null) return;

    final items = <OrderItem>[];
    _quantities.forEach((id, qty) {
      final dish = repo.dishById(id);
      if (dish != null) {
        items.add(OrderItem(
          dishId: dish.id,
          name: dish.name,
          price: dish.price,
          qty: qty,
        ));
      }
    });
    if (items.isEmpty) {
      showMessage(context, 'Выберите хотя бы одно блюдо');
      return;
    }

    setState(() => _busy = true);
    await dataCubit.run(
      (r) => r.createOrder(
        restaurantId: widget.restaurantId,
        tableId: widget.tableId,
        user: user,
        items: items,
        comment: _commentCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    showMessage(context, 'Заказ отправлен на кухню');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final table = repo.tableById(widget.tableId);
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
      appBar: AppBar(
        title: Text(table == null ? 'Новый заказ' : 'Заказ · стол №${table.number}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          DishPicker(
            dishes: dishes,
            quantities: _quantities,
            onChanged: (q) => setState(() => _quantities = q),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentCtrl,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: fieldDecoration('Комментарий для кухни', Icons.edit_note,
                hint: 'Например: без лука, прожарка medium'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: (count == 0 || _busy) ? null : _send,
            icon: const Icon(Icons.send),
            label: Text(count == 0
                ? 'Выберите блюда'
                : 'Отправить на кухню · ${money(total)}'),
          ),
        ),
      ),
    );
  }
}
