import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/journal_bloc.dart';
import '../blocs/theme_bloc.dart';
import '../blocs/workers_bloc.dart';
import '../services/file_service.dart';
import '../theme/app_theme.dart';
import '../utils/actions.dart';
import 'checklist_screen.dart';
import 'dashboard_screen.dart';
import 'journal_screen.dart';
import 'workers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  static const _titles = [
    'Сводка',
    'Журнал обслуживания',
    'Чек-листы',
    'Рабочие'
  ];

  void _showColorDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Цвет интерфейса'),
        content: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < accentOptions.length; i++)
                  GestureDetector(
                    onTap: () =>
                        context.read<ThemeBloc>().add(AccentSelected(i)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: accentOptions[i].color,
                          child: themeState.accentIndex == i
                              ? const Icon(Icons.check)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(accentOptions[i].name,
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveReport() async {
    final entries = context.read<JournalBloc>().state.entries;
    final workers = context.read<WorkersBloc>().state.workers;
    final fileService = context.read<FileService>();

    try {
      final path = await fileService.saveReport(buildReport(entries, workers));
      if (!mounted) return;
      showMessage(
        context,
        path == 'clipboard'
            ? 'Отчёт скопирован в буфер обмена'
            : path == null
                ? 'Не удалось сохранить отчёт'
                : 'Отчёт сохранён: $path',
      );
    } catch (_) {
      if (!mounted) return;
      showMessage(context, 'Не удалось сохранить файл');
    }
  }

  Future<void> _logout() async {
    final ok = await askConfirm(
      context,
      title: 'Выйти из аккаунта?',
      text: 'Чтобы войти снова, введите свой номер телефона.',
      yesLabel: 'Выйти',
    );
    if (ok && mounted) {
      context.read<AuthBloc>().add(UserLoggedOut());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JournalBloc, JournalState>(
      listenWhen: (prev, curr) =>
          prev.message != curr.message && curr.message != null,
      listener: (context, state) => showMessage(context, state.message!),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_tab]),
          actions: [
            BlocBuilder<JournalBloc, JournalState>(
              builder: (context, state) {
                if (state.syncing) {
                  return const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  );
                }
                return IconButton(
                  tooltip: 'Отправить на сервер',
                  icon: Badge(
                    isLabelVisible: state.unsyncedCount > 0,
                    label: Text('${state.unsyncedCount}'),
                    child: const Icon(Icons.cloud_upload_outlined),
                  ),
                  onPressed: () =>
                      context.read<JournalBloc>().add(SyncRequested()),
                );
              },
            ),
            IconButton(
              tooltip: 'Цвет интерфейса',
              icon: const Icon(Icons.palette_outlined),
              onPressed: _showColorDialog,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') _saveReport();
                if (value == 'logout') _logout();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'report',
                  child: ListTile(
                    leading: Icon(Icons.description_outlined),
                    title: Text('Сохранить отчёт в файл'),
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Выйти'),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          children: [
            DashboardScreen(onNavigate: (i) => setState(() => _tab = i)),
            const JournalScreen(),
            const ChecklistScreen(),
            const WorkersScreen(),
          ],
        ),
        floatingActionButton: _buildFab(),
        bottomNavigationBar: NavigationBar(
          backgroundColor: cardColor,
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Сводка',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Журнал',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: 'Чек-листы',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'Рабочие',
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFab() {
    if (_tab == 1) {
      return FloatingActionButton.extended(
        onPressed: () => openAddEntry(context),
        icon: const Icon(Icons.add),
        label: const Text('Запись'),
      );
    }
    if (_tab == 3) {
      return FloatingActionButton.extended(
        onPressed: () => openAddWorker(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Рабочий'),
      );
    }
    return null;
  }
}
