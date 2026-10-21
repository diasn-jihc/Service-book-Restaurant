import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/workers_bloc.dart';
import '../models/worker.dart';
import '../utils/actions.dart';
import '../widgets/worker_form.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  void _register(BuildContext context, Worker newWorker) {
    final workers = context.read<WorkersBloc>().state.workers;

    Worker? existing;
    for (final w in workers) {
      if (w.phone == newWorker.phone) existing = w;
    }

    if (existing != null) {
      context.read<AuthBloc>().add(UserRegistered(existing));
      showMessage(context, 'С возвращением, ${existing.fullName}!');
    } else {
      context.read<WorkersBloc>().add(WorkerAdded(newWorker));
      context.read<AuthBloc>().add(UserRegistered(newWorker));
    }
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
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: accent,
                    child: const Icon(Icons.restaurant, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Сервисная книжка',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Регистрация сотрудника ресторана'),
                  const SizedBox(height: 28),
                  WorkerForm(
                    submitLabel: 'Зарегистрироваться',
                    onSubmit: (worker) => _register(context, worker),
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
