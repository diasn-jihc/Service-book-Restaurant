import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/workers_bloc.dart';
import '../services/storage_service.dart';
import '../utils/actions.dart';
import '../widgets/field_decoration.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phone.text.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final storage = context.read<StorageService>();
    final matches = context
        .read<WorkersBloc>()
        .state
        .workers
        .where((item) => item.phone == phone);
    final worker = matches.isEmpty ? null : matches.first;
    if (worker == null || !storage.verifyPassword(phone, _password.text)) {
      showMessage(context, 'Неверный номер телефона или пароль');
      return;
    }
    storage.upgradePasswordHash(phone, _password.text);
    context.read<AuthBloc>().add(UserLoggedIn(worker));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Вход')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.restaurant, size: 64),
                      const SizedBox(height: 16),
                      Text('Войдите в аккаунт',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: fieldDecoration(
                            'Номер телефона', Icons.phone,
                            hint: '+77011234567'),
                        validator: (value) {
                          final normalized = (value ?? '')
                              .replaceAll(RegExp(r'[\s\-\(\)]'), '');
                          return RegExp(r'^\+?\d{10,15}$').hasMatch(normalized)
                              ? null
                              : 'Введите корректный номер телефона';
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration:
                            fieldDecoration('Пароль', Icons.lock).copyWith(
                          suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off)),
                        ),
                        validator: (value) =>
                            (value ?? '').isEmpty ? 'Введите пароль' : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                          onPressed: _login, child: const Text('Войти')),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                                builder: (_) => const RegistrationScreen())),
                        child: const Text('Нет аккаунта? Зарегистрироваться'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
