import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/data_cubit.dart';
import '../../models/service_entry.dart';
import '../../models/user.dart';
import '../../utils/actions.dart';
import '../../widgets/field_decoration.dart';

/// Новая запись в журнале. Автор — тот, кто вошёл в аккаунт.
class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  EntryCategory _category = EntryCategory.cleaning;
  bool _resolved = true;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;
    final dataCubit = context.data;
    final entry = ServiceEntry(
      id: dataCubit.repo.newId(),
      restaurantId: widget.restaurantId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      workerName: user.name,
      workerRole: user.role,
      category: _category,
      date: DateTime.now(),
      resolved: _resolved,
    );
    await dataCubit.run((r) => r.addEntry(entry));
    if (!mounted) return;
    showMessage(context, 'Запись добавлена');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Новая запись')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in EntryCategory.values)
                  ChoiceChip(
                    avatar: Icon(c.icon, size: 16),
                    label: Text(c.title),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDecoration('Что сделано', Icons.title),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Напишите короткое название'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDecoration('Подробности', Icons.notes),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _resolved,
              onChanged: (v) => setState(() => _resolved = v),
              title: const Text('Вопрос решён'),
              subtitle: const Text('Выключите, если нужно вернуться к этому позже'),
              contentPadding: EdgeInsets.zero,
            ),
            if (user != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Автор: ${user.name} · ${user.role.title}',
                    style: const TextStyle(color: Colors.white70)),
              ),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
