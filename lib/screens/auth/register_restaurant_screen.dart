import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/city_cubit.dart';
import '../../blocs/data_cubit.dart';
import '../../models/restaurant.dart';
import '../../utils/actions.dart';
import '../../utils/formatters.dart';
import '../../utils/phone.dart';
import '../../widgets/city_picker.dart';
import '../../widgets/field_decoration.dart';
import '../../widgets/password_field.dart';
import '../../widgets/photo_picker_row.dart';
import '../../widgets/section_title.dart';
import 'verify_phone_screen.dart';

/// Регистрация ресторана: аккаунт администратора + данные заведения.
class RegisterRestaurantScreen extends StatefulWidget {
  const RegisterRestaurantScreen({super.key});

  @override
  State<RegisterRestaurantScreen> createState() =>
      _RegisterRestaurantScreenState();
}

class _RegisterRestaurantScreenState extends State<RegisterRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _adminCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _pass2Ctrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _descCtrl;

  late String _city;
  String _cuisine = cuisines.first;
  int _open = 600; // 10:00
  int _close = 1380; // 23:00
  int _tablesCount = 6;
  List<String> _photos = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _adminCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _passCtrl = TextEditingController();
    _pass2Ctrl = TextEditingController();
    _nameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _city = context.read<CityCubit>().state;
  }

  @override
  void dispose() {
    _adminCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_open == _close) {
      showMessage(context, 'Время открытия и закрытия не должно совпадать');
      return;
    }

    setState(() => _busy = true);
    final result = await context.data.run(
      (repo) => repo.registerRestaurant(
        adminName: _adminCtrl.text,
        phone: _phoneCtrl.text,
        password: _passCtrl.text,
        name: _nameCtrl.text,
        city: _city,
        address: _addressCtrl.text,
        cuisine: _cuisine,
        description: _descCtrl.text,
        openMinutes: _open,
        closeMinutes: _close,
        tablesCount: _tablesCount,
        photos: _photos,
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.requiresPhoneVerification) {
      final phone = result.verificationPhone!;
      final user = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyPhoneScreen(
            phone: phone,
            onVerify: (code) async {
              final verified = await context.data.run(
                (repo) => repo.verifyGuestPhone(phone, code),
              );
              if (verified == null) return null;
              return context.data.run(
                (repo) => repo.finishRestaurantRegistration(
                  adminName: _adminCtrl.text,
                  phone: phone,
                  name: _nameCtrl.text,
                  city: _city,
                  address: _addressCtrl.text,
                  cuisine: _cuisine,
                  description: _descCtrl.text,
                  openMinutes: _open,
                  closeMinutes: _close,
                  tablesCount: _tablesCount,
                ),
              );
            },
            onResend: () => context.data.run(
              (repo) => repo.resendPhoneSignupCode(phone),
            ),
          ),
        ),
      );
      if (!mounted || user == null) return;
      context.read<AuthBloc>().add(SessionStarted(user));
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final user = result.user;
    if (user == null) {
      showMessage(context, result.error ?? 'Не удалось зарегистрироваться');
      return;
    }
    context.read<AuthBloc>().add(SessionStarted(user));
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация ресторана')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const SectionTitle('Аккаунт администратора'),
            TextFormField(
              controller: _adminCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: fieldDecoration('Ваше имя и фамилия', Icons.person),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Введите имя и фамилию'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
              ],
              decoration: fieldDecoration('Номер телефона', Icons.phone,
                  hint: '+7 701 123 45 67'),
              validator: (v) =>
                  isValidPhone(v ?? '') ? null : 'Введите номер телефона',
            ),
            const SizedBox(height: 14),
            PasswordField(
              controller: _passCtrl,
              label: 'Пароль (минимум 6 символов)',
              validator: (v) => (v == null || v.length < 6)
                  ? 'Пароль слишком короткий'
                  : null,
            ),
            const SizedBox(height: 14),
            PasswordField(
              controller: _pass2Ctrl,
              label: 'Повторите пароль',
              validator: (v) =>
                  v != _passCtrl.text ? 'Пароли не совпадают' : null,
            ),
            const SectionTitle('О ресторане'),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: fieldDecoration('Название ресторана', Icons.storefront),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Введите название'
                  : null,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _chooseCity,
              icon: const Icon(Icons.location_city),
              label: Text('Город: $_city'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  fieldDecoration('Адрес', Icons.place, hint: 'ул. Абая, 150'),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Введите адрес'
                  : null,
            ),
            const SizedBox(height: 16),
            const Text('Кухня'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in cuisines)
                  ChoiceChip(
                    avatar: Icon(cuisineIcon(c), size: 18),
                    label: Text(c),
                    selected: _cuisine == c,
                    onSelected: (_) => setState(() => _cuisine = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDecoration('Описание', Icons.notes),
            ),
            const SectionTitle('Часы работы и столы'),
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
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.table_restaurant),
                const SizedBox(width: 10),
                const Expanded(child: Text('Количество столов в зале')),
                IconButton.filledTonal(
                  onPressed: _tablesCount > 1
                      ? () => setState(() => _tablesCount--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 40,
                  child: Text('$_tablesCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton.filled(
                  onPressed: _tablesCount < 60
                      ? () => setState(() => _tablesCount++)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Кабинки, террасу и количество мест можно настроить '
                'позже в личном кабинете.',
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ),
            const SectionTitle('Фото ресторана'),
            PhotoPickerRow(
              photos: _photos,
              onChanged: (photos) => setState(() => _photos = photos),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Зарегистрировать ресторан'),
            ),
          ],
        ),
      ),
    );
  }
}
