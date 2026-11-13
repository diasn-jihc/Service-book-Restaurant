import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc.dart';
import '../../blocs/data_cubit.dart';
import '../../data/app_repository.dart';
import '../../models/dining_table.dart';
import '../../models/dish.dart';
import '../../models/restaurant.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/restaurant_image.dart';
import '../../widgets/section_title.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/table_tile.dart';
import 'booking_screen.dart';

/// Страница ресторана: фото, информация, столы «сейчас», меню, отзывы.
class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  int _tab = 0;
  int _photoPage = 0;

  void _book() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingScreen(restaurantId: widget.restaurantId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.repo;
    final user = context.read<AuthBloc>().state.user;
    final r = repo.restaurantById(widget.restaurantId);
    if (r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.storefront,
          text: 'Ресторан не найден',
        ),
      );
    }

    final open = repo.isOpenNow(r);
    final isFavorite =
        user != null && repo.isFavorite(user.id, r.id);
    final rating = repo.ratingOf(r.id);
    final reviews = repo.reviewsOf(r.id);
    final photoCount = r.photos.isEmpty ? 1 : r.photos.length;

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _book,
            icon: const Icon(Icons.event_seat),
            label: const Text('Забронировать стол'),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 270,
            backgroundColor: bgColor,
          actions: [
            if (user != null)
              IconButton(
                tooltip: isFavorite ? 'Убрать из избранного' : 'В избранное',
                onPressed: () => context.data.run(
                  (repository) => repository.toggleFavorite(user.id, r.id),
                ),
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.pinkAccent : null,
                ),
              ),
          ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                r.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              background: Stack(
                children: [
                  Positioned.fill(
                    child: PageView.builder(
                      itemCount: photoCount,
                      onPageChanged: (i) => setState(() => _photoPage = i),
                      itemBuilder: (_, i) => RestaurantImage(
                        restaurant: r,
                        photoIndex: i,
                        height: 320,
                        radius: 0,
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, bgColor],
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (photoCount > 1)
                    Positioned(
                      bottom: 54,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < photoCount; i++)
                            Container(
                              width: i == _photoPage ? 18 : 7,
                              height: 7,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: i == _photoPage
                                    ? Colors.white
                                    : Colors.white54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusChip(
                        label: open ? 'Открыто' : 'Закрыто',
                        color: open ? freeColor : busyColor,
                        icon: Icons.circle,
                      ),
                      StatusChip(
                        label: r.cuisine,
                        color: skyColor,
                        icon: cuisineIcon(r.cuisine),
                      ),
                      if (reviews.isNotEmpty) ...[
                        StarRow(rating: rating),
                        Text(
                          '${rating.toStringAsFixed(1)} (${reviews.length})',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(Icons.place_outlined, '${r.city}, ${r.address}'),
                  _InfoRow(Icons.schedule, 'Работает: ${r.hoursLabel}'),
                  _InfoRow(Icons.phone_outlined, r.phone),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (final entry in const [
                        (0, 'Столы'),
                        (1, 'Меню'),
                        (2, 'Отзывы'),
                      ]) ...[
                        ChoiceChip(
                          label: Text(entry.$2),
                          selected: _tab == entry.$1,
                          onSelected: (_) => setState(() => _tab = entry.$1),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_tab == 0) _TablesTab(restaurant: r, repo: repo),
                  if (_tab == 1) _MenuTab(dishes: repo.dishesOf(r.id)),
                  if (_tab == 2) _ReviewsTab(restaurantId: r.id, repo: repo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Столы «прямо сейчас»: какие свободны, какие заняты, кабинки отдельно.
class _TablesTab extends StatelessWidget {
  const _TablesTab({required this.restaurant, required this.repo});

  final Restaurant restaurant;
  final AppRepository repo;

  @override
  Widget build(BuildContext context) {
    final tables = repo.tablesOf(restaurant.id);
    final free = repo.tablesCount(restaurant.id, TableStatus.free);
    final reserved = repo.tablesCount(restaurant.id, TableStatus.reserved);
    final busy = repo.tablesCount(restaurant.id, TableStatus.occupied);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (restaurant.description.isNotEmpty) ...[
          const SectionTitle('О ресторане'),
          Text(restaurant.description,
              style: const TextStyle(color: Colors.white70, height: 1.4)),
        ],
        const SectionTitle('Столы сейчас'),
        AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Count('$free', 'Свободно', freeColor),
              _Count('$reserved', 'Забронировано', reservedColor),
              _Count('$busy', 'Занято', busyColor),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const TableLegend(),
        if (tables.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Столы ещё не добавлены')),
          ),
        for (final zone in TableZone.values) ...[
          if (tables.any((t) => t.zone == zone)) ...[
            SectionTitle(zone.plural),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final t in tables.where((t) => t.zone == zone))
                  TableTile(table: t, status: repo.statusOf(t)),
              ],
            ),
          ],
        ],
        const SizedBox(height: 8),
        const Text(
          'Нажмите «Забронировать стол», чтобы выбрать дату, время и стол.',
          style: TextStyle(fontSize: 12, color: Colors.white60),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _MenuTab extends StatelessWidget {
  const _MenuTab({required this.dishes});

  final List<Dish> dishes;

  @override
  Widget build(BuildContext context) {
    if (dishes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('Меню пока не добавлено')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in DishCategory.values)
          if (dishes.any((d) => d.category == category)) ...[
            SectionTitle(category.title),
            for (final dish in dishes.where((d) => d.category == category))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Opacity(
                    opacity: dish.available ? 1 : 0.45,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dish.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall),
                              if (dish.description.isNotEmpty)
                                Text(dish.description,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Text(
                          dish.available ? money(dish.price) : 'Нет в наличии',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
      ],
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.restaurantId, required this.repo});

  final String restaurantId;
  final AppRepository repo;

  @override
  Widget build(BuildContext context) {
    final reviews = repo.reviewsOf(restaurantId);
    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Отзывов пока нет. Оставить отзыв можно после визита.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        for (final review in reviews)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(review.userName,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Text(shortDateFormat.format(review.createdAt),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  StarRow(rating: review.stars.toDouble()),
                  if (review.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(review.text),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
