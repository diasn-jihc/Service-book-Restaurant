import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../constants.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone.dart';
import '../../widgets/app_card.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/field_decoration.dart';
import '../../widgets/password_field.dart';
import 'register_guest_screen.dart';
import 'register_restaurant_screen.dart';

/// Первый экран: вход по номеру телефона и паролю.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passCtrl;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController();
    _passCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    context
        .read<AuthBloc>()
        .add(LoginRequested(_phoneCtrl.text, _passCtrl.text));
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  const AuthHeader(
                    subtitle: 'Рестораны, брони и сервис в одном приложении',
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+\-\s\(\)]')),
                          ],
                          decoration: fieldDecoration(
                            'Номер телефона',
                            Icons.phone,
                            hint: '+7 701 123 45 67',
                          ),
                          validator: (v) => isValidPhone(v ?? '')
                              ? null
                              : 'Введите номер телефона',
                        ),
                        const SizedBox(height: 14),
                        PasswordField(
                          controller: _passCtrl,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Введите пароль'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final error = state.error;
                      if (error == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: busyColor),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _login,
                      child: const Text('Войти'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('или'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _open(const RegisterGuestScreen()),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Я гость — создать аккаунт'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _open(const RegisterRestaurantScreen()),
                      icon: const Icon(Icons.storefront),
                      label: const Text('Зарегистрировать ресторан'),
                    ),
                  ),
                  if (kSeedDemoData) ...[
                    const SizedBox(height: 24),
                    const AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Демо-аккаунты (пароль $demoPassword)',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 6),
                          Text('Гость: +77000000000'),
                          Text('Администратор ресторана: +77000000001'),
                          Text('Официант: +77000000011'),
                          Text('Повар: +77000000012'),
                          Text('Шеф-повар: +77000000013'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
