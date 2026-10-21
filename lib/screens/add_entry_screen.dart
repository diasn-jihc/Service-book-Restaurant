import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/workers_bloc.dart';
import '../models/service_entry.dart';
import '../models/worker.dart';
import '../utils/formatters.dart';
import '../widgets/field_decoration.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late Worker _responsible;

  EntryCategory _category = EntryCategory.cleaning;
  DateTime _date = DateTime.now();
  bool _needsAttention = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _responsible = context.read<AuthBloc>().state.user!;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final day = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (day == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted) return;

    setState(() {
      _date = DateTime(
        day.year,
        day.month,
        day.day,
        time?.hour ?? _date.hour,
        time?.minute ?? _date.minute,
      );
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final entry = ServiceEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      workerName: _responsible.fullName,
      workerRole: _responsible.role,
      category: _category,
      date: _date,
      resolved: !_needsAttention,
    );
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final workers = context.watch<WorkersBloc>().state.workers;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Новая запись')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDecoration(
                'Название',
                Icons.edit_note,
                hint: 'Например: мойка холодильной камеры',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Введите название' : null,
            ),
            const SizedBox(height: 20),
            Text('Категория', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in EntryCategory.values)
                  ChoiceChip(
                    avatar: Icon(c.icon, size: 18),
                    label: Text(c.title),
                    selected: _category == c,
                    selectedColor: accent,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Ответственный', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final w in workers)
                  ChoiceChip(
                    avatar: Icon(w.role.icon, size: 18),
                    label: Text(w.fullName),
                    selected: _responsible.id == w.id,
                    selectedColor: accent,
                    onSelected: (_) => setState(() => _responsible = w),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDecoration('Описание', Icons.notes),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text(dateTimeFormat.format(_date)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Требует внимания'),
              subtitle: const Text('Проблема ещё не решена'),
              value: _needsAttention,
              onChanged: (v) => setState(() => _needsAttention = v),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Сохранить запись'),
            ),
          ],
        ),
      ),
    );
  }
}
