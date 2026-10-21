import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/checklist_bloc.dart';
import '../blocs/guests_cubit.dart';
import '../blocs/journal_bloc.dart';
import '../blocs/workers_bloc.dart';
import '../models/checklist_item.dart';
import '../models/meal.dart';
import '../models/worker.dart';
import '../services/api_client.dart';
import '../utils/actions.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/entry_tile.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onNavigate});

  final void Function(int tab) onNavigate;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Meal> _mealFuture;

  @override
  void initState() {
    super.initState();
    _loadMeal();
  }

  void _loadMeal() {
    _mealFuture = context.read<ApiClient>().fetchRandomMeal();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final journal = context.watch<JournalBloc>().state;
    final workers = context.watch<WorkersBloc>().state.workers;
    final checklist = context.watch<ChecklistBloc>().state;
    final accent = Theme.of(context).colorScheme.primary;
    final recent = journal.entries.take(3).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user != null)
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: accent,
                  child: Icon(user.role.icon, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Здравствуйте,',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text('${user.role.title} • '
                          '${longDateFormat.format(DateTime.now())}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        AppCard(
          child: BlocBuilder<GuestsCubit, int>(
            builder: (context, guests) {
              return Row(
                children: [
                  const Icon(Icons.groups, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Гостей в зале'),
                        Text(
                          '$guests',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Минус гость',
                    onPressed: () => context.read<GuestsCubit>().remove(),
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Плюс гость',
                    onPressed: () => context.read<GuestsCubit>().add(),
                    icon: const Icon(Icons.add),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.today,
                value: '${journal.todayCount}',
                label: 'Записей сегодня',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                icon: Icons.warning_amber_rounded,
                value: '${journal.unresolvedCount}',
                label: 'Требуют внимания',
                warning: journal.unresolvedCount > 0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                icon: Icons.badge,
                value: '${workers.length}',
                label: 'Рабочих',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _ProgressCard(
          title: 'Открытие смены',
          icon: Icons.wb_sunny,
          done: checklist.doneCount(ChecklistType.opening),
          total: checklist.itemsOf(ChecklistType.opening).length,
          progress: checklist.progress(ChecklistType.opening),
          onTap: () => widget.onNavigate(2),
        ),
        const SizedBox(height: 8),
        _ProgressCard(
          title: 'Закрытие смены',
          icon: Icons.nightlight_round,
          done: checklist.doneCount(ChecklistType.closing),
          total: checklist.itemsOf(ChecklistType.closing).length,
          progress: checklist.progress(ChecklistType.closing),
          onTap: () => widget.onNavigate(2),
        ),
        const SizedBox(height: 12),

        _buildMealCard(),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: Text('Последние записи',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            TextButton(
              onPressed: () => widget.onNavigate(1),
              child: const Text('Все'),
            ),
          ],
        ),
        if (recent.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Записей пока нет. Добавьте первую!'),
          )
        else
          for (final entry in recent) ...[
            EntryTile(entry: entry, onTap: () => openEntry(context, entry)),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 8),

        FilledButton.icon(
          onPressed: () => openAddEntry(context),
          icon: const Icon(Icons.add),
          label: const Text('Добавить запись в журнал'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => openAddWorker(context),
          icon: const Icon(Icons.person_add),
          label: const Text('Добавить рабочего'),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            journal.lastSync == null
                ? 'Данные ещё не отправлялись на сервер'
                : 'Последняя отправка: ${dateTimeFormat.format(journal.lastSync!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard() {
    return AppCard(
      child: FutureBuilder<Meal>(
        future: _mealFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Row(
              children: [
                const Icon(Icons.wifi_off),
                const SizedBox(width: 12),
                const Expanded(child: Text('Не удалось загрузить блюдо дня')),
                IconButton(
                  tooltip: 'Повторить',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(_loadMeal),
                ),
              ],
            );
          }

          final meal = snapshot.data!;
          return Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  meal.imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 90,
                    height: 90,
                    child: Icon(Icons.restaurant, size: 40),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Блюдо дня', style: TextStyle(fontSize: 12)),
                    Text(
                      meal.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('${meal.category} • ${meal.area}'),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Другое блюдо',
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(_loadMeal),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.icon,
    required this.done,
    required this.total,
    required this.progress,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final int done;
  final int total;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Text('$done / $total'),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
