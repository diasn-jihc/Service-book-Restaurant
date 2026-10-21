import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/worker.dart';
import '../utils/phone_utils.dart';
import 'field_decoration.dart';

class WorkerForm extends StatefulWidget {
  const WorkerForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.onSubmitWithPassword,
    this.initialWorker,
  });

  final String submitLabel;
  final void Function(Worker worker) onSubmit;
  final void Function(Worker worker, String password)? onSubmitWithPassword;
  final Worker? initialWorker;

  @override
  State<WorkerForm> createState() => _WorkerFormState();
}

class _WorkerFormState extends State<WorkerForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passwordCtrl;
  bool _obscurePassword = true;
  late WorkerRole _role;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialWorker;
    _nameCtrl = TextEditingController(text: initial?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: initial?.phone ?? '');
    _passwordCtrl = TextEditingController();
    _role = initial?.role ?? WorkerRole.waiter;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final text = (value ?? '').trim();
    if (text.length < 3) return 'Введите имя и фамилию';
    return null;
  }

  String? _validatePhone(String? value) {
    if (!isValidPhone(value ?? '')) {
      return 'Введите номер, например +77011234567';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final worker = Worker(
      id: widget.initialWorker?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      fullName: _nameCtrl.text.trim(),
      phone: normalizePhone(_phoneCtrl.text),
      role: _role,
    );
    final submit = widget.onSubmitWithPassword;
    if (submit != null) {
      submit(worker, _passwordCtrl.text);
    } else {
      widget.onSubmit(worker);
    }
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
          if (widget.onSubmitWithPassword != null) ...[
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration:
                  fieldDecoration('Пароль (минимум 6 символов)', Icons.lock)
                      .copyWith(
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                ),
              ),
              validator: (value) => (value ?? '').length < 6
                  ? 'Пароль должен содержать минимум 6 символов'
                  : null,
            ),
          ],
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
