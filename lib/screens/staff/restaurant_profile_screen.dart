import 'package:flutter/material.dart';

import '../../blocs/data_cubit.dart';
import '../../models/restaurant.dart';
import '../../utils/actions.dart';
import '../../utils/formatters.dart';
import '../../widgets/city_picker.dart';
import '../../widgets/field_decoration.dart';
import '../../widgets/photo_picker_row.dart';
import '../../widgets/section_title.dart';

/// Профиль ресторана: название, город, адрес, часы работы и фотографии.
class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  State<RestaurantProfileScreen> createState() =>
      _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _phoneCtrl;
  late String _city;
  late String _cuisine;
  late int _open;
  late int _close;
  late List<String> _photos;

  @override
  void initState() {
    super.initState();
    final r = context.data.repo.restaurantById(widget.restaurantId)!;
    _nameCtrl = TextEditingController(text: r.name);
    _addressCtrl = TextEditingController(text: r.address);
    _descCtrl = TextEditingController(text: r.description);
    _phoneCtrl = TextEditingController(text: r.phone);
    _city = r.city;
    _cuisine = r.cuisine;
    _open = r.openMinutes;
    _close = r.closeMinutes;
    _photos = [...r.photos];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _chooseCity() async {
    final city = await pickCity(context, _city);
    if (city != null) setState(() => _city = city);
  }

  Future<void> _pickTime(bool isOpen) async {
    final current = isOpen ? _open : _close;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (current ~/ 60) % 24, minute: current % 60),
    );
    if (picked == null) return;
    setState(() {
      final minutes = picked.hour * 60 + picked.minute;
      if (isOpen) {
        _open = minutes;
      } else {
        _close = minutes;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_open == _close) {
      showMessage(context, 'Время открытия и закрытия не должно совпадать');
      return;
    }
    final dataCubit = context.data;
    final old = dataCubit.repo.restaurantById(widget.restaurantId);
    if (old == null) return;

    final updated = old.copyWith(
      name: _nameCtrl.text.trim(),
      city: _city,
      address: _addressCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      cuisine: _cuisine,
      phone: _phoneCtrl.text.trim(),
      openMinutes: _open,
      closeMinutes: _close,
      photos: _photos,
    );
    await dataCubit.run((r) => r.updateRestaurant(updated));
    if (!mounted) return;
    showMessage(context, 'Профиль ресторана сохранён');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль ресторана')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            const SectionTitle('Фотографии'),
            PhotoPickerRow(
              photos: _photos,
              onChanged: (p) => setState(() => _photos = p),
            ),
            const SectionTitle('Основное'),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: fieldDecoration('Название', Icons.storefront),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Введите название'
                  : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _chooseCity,
              icon: const Icon(Icons.location_city),
              label: Text('Город: $_city'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: fieldDecoration('Адрес', Icons.place_outlined),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Введите адрес'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: fieldDecoration('Телефон ресторана', Icons.phone),
            ),
            const SectionTitle('Кухня'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in cuisines)
                  ChoiceChip(
                    avatar: Icon(cuisineIcon(c), size: 16),
                    label: Text(c),
                    selected: _cuisine == c,
                    onSelected: (_) => setState(() => _cuisine = c),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDecoration('Описание', Icons.notes),
            ),
            const SectionTitle('Часы работы'),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(true),
                    icon: const Icon(Icons.wb_sunny_outlined),
                    label: Text('Открытие ${minutesLabel(_open)}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(false),
                    icon: const Icon(Icons.nightlight_outlined),
                    label: Text('Закрытие ${minutesLabel(_close)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
