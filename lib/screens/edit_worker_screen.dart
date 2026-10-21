import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/workers_bloc.dart';
import '../models/worker.dart';
import '../utils/actions.dart';
import '../widgets/worker_form.dart';

class EditWorkerScreen extends StatelessWidget {
  const EditWorkerScreen({super.key, required this.worker});

  final Worker worker;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Изменить сотрудника')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: WorkerForm(
                initialWorker: worker,
                submitLabel: 'Сохранить изменения',
                onSubmit: (updated) {
                  final duplicate = context
                      .read<WorkersBloc>()
                      .state
                      .workers
                      .any((item) =>
                          item.phone == updated.phone && item.id != updated.id);
                  if (duplicate) {
                    showMessage(context,
                        'Этот номер уже используется другим сотрудником');
                    return;
                  }
                  Navigator.of(context).pop(updated);
                },
              ),
            ),
          ),
        ),
      );
}
