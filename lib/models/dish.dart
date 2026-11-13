import 'package:flutter/material.dart';

enum DishCategory { starters, mains, drinks, desserts }

extension DishCategoryInfo on DishCategory {
  String get title {
    switch (this) {
      case DishCategory.starters:
        return 'Закуски';
      case DishCategory.mains:
        return 'Горячее';
      case DishCategory.drinks:
        return 'Напитки';
      case DishCategory.desserts:
        return 'Десерты';
    }
  }

  IconData get icon {
    switch (this) {
      case DishCategory.starters:
        return Icons.tapas;
      case DishCategory.mains:
        return Icons.dinner_dining;
      case DishCategory.drinks:
        return Icons.local_drink;
      case DishCategory.desserts:
        return Icons.cake;
    }
  }
}

/// Блюдо в меню ресторана. Цена в тенге.
class Dish {
  final String id;
  final String restaurantId;
  final String name;
  final int price;
  final DishCategory category;
  final String description;
  final bool available; // false — стоп-лист

  const Dish({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.category,
    this.description = '',
    this.available = true,
  });

  Dish copyWith({
    String? name,
    int? price,
    DishCategory? category,
    String? description,
    bool? available,
  }) {
    return Dish(
      id: id,
      restaurantId: restaurantId,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      description: description ?? this.description,
      available: available ?? this.available,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurantId': restaurantId,
        'name': name,
        'price': price,
        'category': category.name,
        'description': description,
        'available': available,
      };

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      category: DishCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => DishCategory.mains,
      ),
      description: (json['description'] as String?) ?? '',
      available: (json['available'] as bool?) ?? true,
    );
  }
}
