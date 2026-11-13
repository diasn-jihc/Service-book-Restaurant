import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/data_cubit.dart';
import '../../models/user.dart';
import '../../utils/actions.dart';
import '../../utils/phone.dart';
import '../../widgets/app_card.dart';
import '../../widgets/field_decoration.dart';
import '../../widgets/password_field.dart';

/// Сотрудники ресторана. Добавлять и удалять может только администратор.
class StaffListScreen extends StatelessWidget {
  const StaffListScreen({super.key, required this.restaurantId});

  final String restaurantId;

  Future<void> _remove(BuildContext context, AppUser worker) async {
    final ok = await askConfirm(
      context,
      title: 'Удалить сотрудника?',
      text: '${worker.name} больше не сможет войти в кабинет ресторана.',
    );
    if (!ok || !context.mounted) return;
    await context.data.run((r) => r.removeStaff(worker.id));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final me = context.read<AuthBloc>().state.user;
    final canManage = me != null && me.role.canManage;
    final staff = repo.staffOf(restaurantId);

    return Scaffold(
      appBar: AppBar(title: const Text('Сотрудники')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddStaffScreen(restaurantId: restaurantId),
                ),
              ),
              icon: const Icon(Icons.person_add),
              label: const Text('Сотрудник'),
            )
          : null,
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: staff.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final w = staff[i];
          final isMe = me != null && me.id == w.id;
          return AppCard(
            child: Row(
              children: [
                CircleAvatar(child: Icon(w.role.icon)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isMe ? '${w.name} (вы)' : w.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${w.role.title} · ${w.phone}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                if (canManage && !isMe)
                  IconButton(
                    tooltip: 'Удалить',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _remove(context, w),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Добавление сотрудника: имя, телефон, роль и пароль для входа.
class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passCtrl;
  UserRole _role = UserRole.waiter;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _passCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await context.data.run((r) => r.addStaff(
          restaurantId: widget.restaurantId,
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
          password: _passCtrl.text,
          role: _role,
        ));
    if (!mounted) return;
    if (error != null) {
      showMessage(context, error);
      return;
    }
    showMessage(context, 'Сотрудник добавлен');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый сотрудник')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final role in staffRoles)
                  ChoiceChip(
                    avatar: Icon(role.icon, size: 16),
                    label: Text(role.title),
                    selected: _role == role,
                    onSelected: (_) => setState(() => _role = role),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: fieldDecoration('Имя и фамилия', Icons.person),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Введите имя'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ()-]')),
              ],
              decoration: fieldDecoration('Телефон', Icons.phone,
                  hint: '+7 700 000 00 00'),
              validator: (v) =>
                  isValidPhone(v ?? '') ? null : 'Введите номер телефона',
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _passCtrl,
              label: 'Пароль для входа',
              validator: (v) => (v == null || v.length < 6)
                  ? 'Минимум 6 символов'
                  : null,
            ),
            const SizedBox(height: 8),
            const Text(
              'Сотрудник войдёт по номеру телефона и этому паролю.',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}
