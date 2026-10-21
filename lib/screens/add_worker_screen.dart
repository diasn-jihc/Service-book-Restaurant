import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/workers_bloc.dart';
import '../utils/actions.dart';
import '../widgets/worker_form.dart';

class AddWorkerScreen extends StatelessWidget {
  const AddWorkerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый рабочий')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: WorkerForm(
              submitLabel: 'Добавить рабочего',
              onSubmit: (worker) {
                final exists = context
                    .read<WorkersBloc>()
                    .state
                    .workers
                    .any((w) => w.phone == worker.phone);
                if (exists) {
                  showMessage(context, 'Рабочий с таким номером уже есть');
                  return;
                }
                Navigator.of(context).pop(worker);
              },
            ),
          ),
        ),
      ),
    );
  }
}
