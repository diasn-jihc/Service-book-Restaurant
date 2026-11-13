import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../utils/phone_utils.dart';
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
    final phone = normalizePhone(_phone.text);
    context.read<AuthBloc>().add(LoginRequested(phone, _password.text));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Р’С…РѕРґ')),
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
                      Text('Р’РѕР№РґРёС‚Рµ РІ Р°РєРєР°СѓРЅС‚',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: fieldDecoration(
                            'РќРѕРјРµСЂ С‚РµР»РµС„РѕРЅР°', Icons.phone,
                            hint: '+77011234567'),
                        validator: (value) {
                          return isValidPhone(value ?? '')
                              ? null
                              : 'Р’РІРµРґРёС‚Рµ РєРѕСЂСЂРµРєС‚РЅС‹Р№ РЅРѕРјРµСЂ С‚РµР»РµС„РѕРЅР°';
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration:
                            fieldDecoration('РџР°СЂРѕР»СЊ', Icons.lock).copyWith(
                          suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off)),
                        ),
                        validator: (value) =>
                            (value ?? '').isEmpty ? 'Р’РІРµРґРёС‚Рµ РїР°СЂРѕР»СЊ' : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                          onPressed: _login, child: const Text('Р’РѕР№С‚Рё')),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                                builder: (_) => const RegistrationScreen())),
                        child: const Text('РќРµС‚ Р°РєРєР°СѓРЅС‚Р°? Р—Р°СЂРµРіРёСЃС‚СЂРёСЂРѕРІР°С‚СЊСЃСЏ'),
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
