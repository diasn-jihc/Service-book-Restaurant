import 'package:flutter/material.dart';

import '../utils/formatters.dart';

const cuisines = [
  'Казахская',
  'Европейская',
  'Итальянская',
  'Японская',
  'Гриль и стейки',
  'Восточная',
  'Фастфуд',
  'Кофейня',
];

IconData cuisineIcon(String cuisine) {
  switch (cuisine) {
    case 'Казахская':
      return Icons.rice_bowl;
    case 'Итальянская':
      return Icons.local_pizza;
    case 'Японская':
      return Icons.set_meal;
    case 'Гриль и стейки':
      return Icons.outdoor_grill;
    case 'Восточная':
      return Icons.ramen_dining;
    case 'Фастфуд':
      return Icons.fastfood;
    case 'Кофейня':
      return Icons.local_cafe;
    default:
      return Icons.restaurant;
  }
}

class Restaurant {
  final String id;
  final String ownerId;
  final String name;
  final String city;
  final String address;
  final String description;
  final String cuisine;
  final String phone;
  final int openMinutes; // минуты от полуночи, 600 = 10:00
  final int closeMinutes;
  final List<String> photos; // пути к файлам или ссылки

  const Restaurant({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.city,
    required this.address,
    required this.description,
    required this.cuisine,
    required this.phone,
    required this.openMinutes,
    required this.closeMinutes,
    required this.photos,
  });

  String get hoursLabel =>
      '${minutesLabel(openMinutes)} – ${minutesLabel(closeMinutes)}';

  Restaurant copyWith({
    String? name,
    String? city,
    String? address,
    String? description,
    String? cuisine,
    String? phone,
    int? openMinutes,
    int? closeMinutes,
    List<String>? photos,
  }) {
    return Restaurant(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      city: city ?? this.city,
      address: address ?? this.address,
      description: description ?? this.description,
      cuisine: cuisine ?? this.cuisine,
      phone: phone ?? this.phone,
      openMinutes: openMinutes ?? this.openMinutes,
      closeMinutes: closeMinutes ?? this.closeMinutes,
      photos: photos ?? this.photos,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'name': name,
        'city': city,
        'address': address,
        'description': description,
        'cuisine': cuisine,
        'phone': phone,
        'openMinutes': openMinutes,
        'closeMinutes': closeMinutes,
        'photos': photos,
      };

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      address: (json['address'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      cuisine: (json['cuisine'] as String?) ?? cuisines.first,
      phone: (json['phone'] as String?) ?? '',
      openMinutes: (json['openMinutes'] as int?) ?? 600,
      closeMinutes: (json['closeMinutes'] as int?) ?? 1380,
      photos: ((json['photos'] as List<dynamic>?) ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}
