import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/restaurant.dart';

/// Фото ресторана. Если фото нет — красивая заглушка с иконкой кухни.
class RestaurantImage extends StatelessWidget {
  const RestaurantImage({
    super.key,
    required this.restaurant,
    this.photoIndex = 0,
    this.height = 160,
    this.radius = 20,
  });

  final Restaurant restaurant;
  final int photoIndex;
  final double height;
  final double radius;

  Color _baseColor() {
    var sum = 0;
    for (final unit in restaurant.name.codeUnits) {
      sum += unit;
    }
    return HSLColor.fromAHSL(1, (sum % 360).toDouble(), 0.55, 0.32).toColor();
  }

  Widget _placeholder() {
    final base = _baseColor();
    final other = HSLColor.fromColor(base)
        .withHue((HSLColor.fromColor(base).hue + 40) % 360)
        .toColor();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [base, other],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          cuisineIcon(restaurant.cuisine),
          size: 52,
          color: Colors.white60,
        ),
      ),
    );
  }

  Widget _photo(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (kIsWeb) return _placeholder();
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoIndex < restaurant.photos.length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: hasPhoto ? _photo(restaurant.photos[photoIndex]) : _placeholder(),
      ),
    );
  }
}

/// Небольшая картинка по пути (для списка фото при регистрации).
class PhotoThumb extends StatelessWidget {
  const PhotoThumb({super.key, required this.path, this.size = 84});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (path.startsWith('http')) {
      child = Image.network(path, fit: BoxFit.cover);
    } else if (kIsWeb) {
      child = const Icon(Icons.image);
    } else {
      child = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}
