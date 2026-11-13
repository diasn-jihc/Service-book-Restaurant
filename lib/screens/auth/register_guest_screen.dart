import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/city_cubit.dart';
import '../../blocs/data_cubit.dart';
import '../../utils/actions.dart';
import '../../utils/phone.dart';
import '../../widgets/city_picker.dart';
import '../../widgets/field_decoration.dart';
import '../../widgets/password_field.dart';
import 'verify_phone_screen.dart';

/// Регистрация гостя (клиента).
class RegisterGuestScreen extends StatefulWidget {
  const RegisterGuestScreen({super.key});

  @override
  State<RegisterGuestScreen> createState() => _RegisterGuestScreenState();
}

class _RegisterGuestScreenState extends State<RegisterGuestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _pass2Ctrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _passCtrl = TextEditingController();
    _pass2Ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _chooseCity() async {
    final cubit = context.read<CityCubit>();
    final city = await pickCity(context, cubit.state);
    if (city != null) cubit.select(city);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final result = await context.data.run(
      (repo) => repo.registerGuest(
        name: _nameCtrl.text,
        phone: _phoneCtrl.text,
        password: _passCtrl.text,
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
            onVerify: (code) => context.data.run(
              (repo) => repo.verifyGuestPhone(phone, code),
            ),
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
    final city = context.watch<CityCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация гостя')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Выбирайте рестораны в своём городе, бронируйте столы '
              'и заказывайте блюда заранее.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: fieldDecoration('Имя', Icons.person),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Введите имя'
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
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _chooseCity,
              icon: const Icon(Icons.location_city),
              label: Text('Мой город: $city'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Создать аккаунт'),
            ),
          ],
        ),
      ),
    );
  }
}
