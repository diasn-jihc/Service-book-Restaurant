import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/city_cubit.dart';
import '../../blocs/data_cubit.dart';
import '../../data/app_repository.dart';
import '../../models/dining_table.dart';
import '../../models/meal.dart';
import '../../models/restaurant.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/city_picker.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/restaurant_image.dart';
import '../../widgets/section_title.dart';
import 'restaurant_detail_screen.dart';

/// Вкладка «Рестораны»: выбор города, поиск, фильтр по кухне, список.
class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  String _query = '';
  String? _cuisine;
  bool _favoritesOnly = false;
  late final Future<Meal> _mealFuture;

  @override
  void initState() {
    super.initState();
    _mealFuture = context.read<ApiClient>().fetchRandomMeal();
  }

  Future<void> _chooseCity() async {
    final cubit = context.read<CityCubit>();
    final city = await pickCity(context, cubit.state);
    if (city == null) return;
    cubit.select(city);
    setState(() => _cuisine = null);
  }

  void _open(Restaurant restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(restaurantId: restaurant.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final city = context.watch<CityCubit>().state;
    final repo = context.repo;
    final authUser = context.read<AuthBloc>().state.user;
    final user = authUser == null ? null : repo.userById(authUser.id);
    final firstName = (user?.name ?? '').split(' ').first;

    final inCity = repo.restaurantsIn(city);
    final favoriteIds = user?.favoriteRestaurantIds ?? const <String>[];
    final cuisinesHere = inCity.map((r) => r.cuisine).toSet().toList();
    final query = _query.trim().toLowerCase();
    final shown = inCity.where((r) {
      final matchesQuery = query.isEmpty ||
          r.name.toLowerCase().contains(query) ||
          r.cuisine.toLowerCase().contains(query) ||
          r.address.toLowerCase().contains(query) ||
          r.description.toLowerCase().contains(query);
      final matchesCuisine = _cuisine == null || r.cuisine == _cuisine;
      final matchesFavorite = !_favoritesOnly || favoriteIds.contains(r.id);
      return matchesQuery && matchesCuisine && matchesFavorite;
    }).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstName.isEmpty
                          ? 'Здравствуйте!'
                          : 'Здравствуйте, $firstName!',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Куда пойдём?',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _chooseCity,
                icon: const Icon(Icons.location_on, size: 20),
                label: Text(city),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Название, кухня или адрес',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Очистить поиск',
                      onPressed: () => setState(() => _query = ''),
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              avatar: Icon(
                _favoritesOnly ? Icons.favorite : Icons.favorite_border,
                size: 18,
              ),
              label: Text('Избранное (${favoriteIds.length})'),
              selected: _favoritesOnly,
              onSelected: (selected) =>
                  setState(() => _favoritesOnly = selected),
            ),
          ),
          if (cuisinesHere.length > 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('Все'),
                    selected: _cuisine == null,
                    onSelected: (_) => setState(() => _cuisine = null),
                  ),
                  for (final c in cuisinesHere) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: Icon(cuisineIcon(c), size: 18),
                      label: Text(c),
                      selected: _cuisine == c,
                      onSelected: (_) => setState(() => _cuisine = c),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          _MealIdeaCard(future: _mealFuture),
          SectionTitle('Рестораны: $city (${shown.length})'),
          if (shown.isEmpty)
            const SizedBox(
              height: 260,
              child: EmptyState(
                icon: Icons.search_off,
                text: 'В этом городе пока нет подходящих ресторанов.\n'
                    'Попробуйте другой город или сбросьте фильтр.',
              ),
            )
          else
            for (final r in shown) ...[
              _RestaurantCard(
                restaurant: r,
                repo: repo,
                isFavorite: favoriteIds.contains(r.id),
                onFavoriteTap: user == null
                    ? null
                    : () => context.data.run(
                          (repository) =>
                              repository.toggleFavorite(user.id, r.id),
                        ),
                onTap: () => _open(r),
              ),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.restaurant,
    required this.repo,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  final Restaurant restaurant;
  final AppRepository repo;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final VoidCallback onTap;

  Widget _badge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final rating = repo.ratingOf(r.id);
    final reviewsCount = repo.reviewsOf(r.id).length;
    final totalTables = repo.tablesOf(r.id).length;
    final freeTables = repo.tablesCount(r.id, TableStatus.free);
    final open = repo.isOpenNow(r);

    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              RestaurantImage(restaurant: r, height: 160, radius: 14),
              Positioned(
                top: 10,
                left: 10,
                child: _badge(
                  open ? 'Открыто' : 'Закрыто',
                  open ? freeColor : busyColor,
                  Icons.circle,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _badge(
                  'Свободно: $freeTables из $totalTables',
                  freeTables > 0 ? freeColor : busyColor,
                  Icons.table_restaurant,
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: IconButton.filledTonal(
                  tooltip: isFavorite ? 'Убрать из избранного' : 'В избранное',
                  onPressed: onFavoriteTap,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withAlpha(160),
                    foregroundColor:
                        isFavorite ? Colors.pinkAccent : Colors.white,
                  ),
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (reviewsCount > 0) ...[
                      const Icon(Icons.star_rounded,
                          size: 20, color: Color(0xFFFFC53D)),
                      const SizedBox(width: 2),
                      Text(
                        '${rating.toStringAsFixed(1)} ($reviewsCount)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ] else
                      const Text('Нет оценок',
                          style: TextStyle(color: Colors.white54)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(cuisineIcon(r.cuisine), size: 16),
                    const SizedBox(width: 6),
                    Text(r.cuisine),
                    const SizedBox(width: 14),
                    const Icon(Icons.schedule, size: 16),
                    const SizedBox(width: 6),
                    Text(r.hoursLabel),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «Идея дня»: блюдо, которое приходит с сервера (HTTP + JSON).
class _MealIdeaCard extends StatelessWidget {
  const _MealIdeaCard({required this.future});

  final Future<Meal> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Meal>(
      future: future,
      builder: (context, snapshot) {
        final meal = snapshot.data;
        if (meal == null) return const SizedBox.shrink(); // загрузка или ошибка

        return AppCard(
          padding: const EdgeInsets.all(10),
          gradient: accentGradient(Theme.of(context).colorScheme.primary),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  meal.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 64,
                    height: 64,
                    child: Icon(Icons.restaurant),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Идея дня', style: TextStyle(fontSize: 12)),
                    Text(
                      meal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text('${meal.category} • ${meal.area}',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
