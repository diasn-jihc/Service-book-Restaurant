import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/worker.dart';
import 'field_decoration.dart';

class WorkerForm extends StatefulWidget {
  const WorkerForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
  });

  final String submitLabel;
  final void Function(Worker worker) onSubmit;

  @override
  State<WorkerForm> createState() => _WorkerFormState();
}

class _WorkerFormState extends State<WorkerForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  WorkerRole _role = WorkerRole.waiter;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _cleanPhone(String text) =>
      text.replaceAll(RegExp(r'[\s\-\(\)]'), '');

  String? _validateName(String? value) {
    final text = (value ?? '').trim();
    if (text.length < 3) return 'Введите имя и фамилию';
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = _cleanPhone(value ?? '');
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(phone)) {
      return 'Введите номер, например +77011234567';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final worker = Worker(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      fullName: _nameCtrl.text.trim(),
      phone: _cleanPhone(_phoneCtrl.text),
      role: _role,
    );
    widget.onSubmit(worker);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: fieldDecoration('Имя и фамилия', Icons.person),
            validator: _validateName,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
            ],
            decoration: fieldDecoration(
              'Номер телефона',
              Icons.phone,
              hint: '+7 701 123 45 67',
            ),
            validator: _validatePhone,
          ),
          const SizedBox(height: 20),
          Text('Роль', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final role in WorkerRole.values)
                ChoiceChip(
                  avatar: Icon(role.icon, size: 18),
                  label: Text(role.title),
                  selected: _role == role,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  onSelected: (_) => setState(() => _role = role),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check),
            label: Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
