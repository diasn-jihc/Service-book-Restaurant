import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/data_cubit.dart';
import '../../models/dish.dart';
import '../../models/user.dart';
import '../../utils/actions.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/field_decoration.dart';

/// Меню ресторана: стоп-лист, добавление, правка и удаление блюд.
class MenuManageScreen extends StatelessWidget {
  const MenuManageScreen({super.key, required this.restaurantId});

  final String restaurantId;

  Future<void> _delete(BuildContext context, Dish dish) async {
    final ok = await askConfirm(
      context,
      title: 'Удалить «${dish.name}»?',
      text: 'Блюдо пропадёт из меню для гостей.',
    );
    if (!ok || !context.mounted) return;
    await context.data.run((r) => r.deleteDish(dish.id));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final user = context.read<AuthBloc>().state.user;
    final canEdit = user != null && user.role.canEditMenu;
    final dishes = repo.dishesOf(restaurantId);

    return Scaffold(
      appBar: AppBar(title: const Text('Меню')),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => showDishForm(context, restaurantId: restaurantId),
              icon: const Icon(Icons.add),
              label: const Text('Блюдо'),
            )
          : null,
      body: dishes.isEmpty
          ? const EmptyState(icon: Icons.restaurant_menu, text: 'Меню пустое')
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                for (final category in DishCategory.values)
                  ..._section(context, category,
                      dishes.where((d) => d.category == category).toList(), canEdit),
              ],
            ),
    );
  }

  List<Widget> _section(BuildContext context, DishCategory category,
      List<Dish> list, bool canEdit) {
    if (list.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Row(
          children: [
            Icon(category.icon, size: 20),
            const SizedBox(width: 8),
            Text(category.title,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
      for (final dish in list)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: dish.available ? 1 : 0.5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dish.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          dish.available
                              ? money(dish.price)
                              : '${money(dish.price)} · в стоп-листе',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                if (canEdit) ...[
                  Switch(
                    value: dish.available,
                    onChanged: (v) => context.data.run(
                        (r) => r.updateDish(dish.copyWith(available: v))),
                  ),
                  IconButton(
                    tooltip: 'Изменить',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => showDishForm(context,
                        restaurantId: restaurantId, dish: dish),
                  ),
                  IconButton(
                    tooltip: 'Удалить',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, dish),
                  ),
                ],
              ],
            ),
          ),
        ),
    ];
  }
}

/// Форма блюда: если [dish] передан — правка, иначе новое блюдо.
Future<void> showDishForm(
  BuildContext context, {
  required String restaurantId,
  Dish? dish,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _DishForm(restaurantId: restaurantId, dish: dish),
  );
}

class _DishForm extends StatefulWidget {
  const _DishForm({required this.restaurantId, this.dish});

  final String restaurantId;
  final Dish? dish;

  @override
  State<_DishForm> createState() => _DishFormState();
}

class _DishFormState extends State<_DishForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late DishCategory _category;

  @override
  void initState() {
    super.initState();
    final d = widget.dish;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _priceCtrl = TextEditingController(text: d == null ? '' : '${d.price}');
    _descCtrl = TextEditingController(text: d?.description ?? '');
    _category = d?.category ?? DishCategory.mains;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final dataCubit = context.data;
    final price = int.parse(_priceCtrl.text.trim());
    final old = widget.dish;

    if (old == null) {
      final dish = Dish(
        id: dataCubit.repo.newId(),
        restaurantId: widget.restaurantId,
        name: _nameCtrl.text.trim(),
        price: price,
        category: _category,
        description: _descCtrl.text.trim(),
      );
      await dataCubit.run((r) => r.addDish(dish));
    } else {
      final dish = old.copyWith(
        name: _nameCtrl.text.trim(),
        price: price,
        category: _category,
        description: _descCtrl.text.trim(),
      );
      await dataCubit.run((r) => r.updateDish(dish));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.dish == null ? 'Новое блюдо' : 'Изменить блюдо',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in DishCategory.values)
                    ChoiceChip(
                      avatar: Icon(c.icon, size: 16),
                      label: Text(c.title),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: fieldDecoration('Название', Icons.restaurant),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Введите название'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: fieldDecoration('Цена, ₸', Icons.payments_outlined),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return (n == null || n <= 0) ? 'Введите цену числом' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: fieldDecoration('Описание', Icons.notes),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
