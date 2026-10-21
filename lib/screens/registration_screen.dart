import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/workers_bloc.dart';
import '../models/worker.dart';
import '../services/storage_service.dart';
import '../widgets/worker_form.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  void _register(BuildContext context, Worker worker, String password) {
    final existing = context.read<WorkersBloc>().state.workers.where((item) => item.phone == worker.phone);
    final storage = context.read<StorageService>();
    if (existing.isNotEmpty && storage.hasPassword(worker.phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Этот номер уже зарегистрирован. Войдите в аккаунт.')),
      );
      return;
    }
    context.read<AuthBloc>().add(UserRegistered(existing.isEmpty ? worker : existing.first, password));
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  CircleAvatar(radius: 44, backgroundColor: accent,
                    child: const Icon(Icons.restaurant, size: 48)),
                  const SizedBox(height: 16),
                  Text('Сервисная книжка', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Регистрация сотрудника ресторана'),
                  const SizedBox(height: 28),
                  WorkerForm(
                    submitLabel: 'Зарегистрироваться',
                    onSubmit: (_) {},
                    onSubmitWithPassword: (worker, password) => _register(context, worker, password),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LoginScreen())),
                    child: const Text('Уже есть аккаунт? Войти'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
