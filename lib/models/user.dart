import 'package:flutter/material.dart';

/// Роли: гость (клиент) и сотрудники ресторана.
enum UserRole { guest, admin, chef, waiter, cook, bartender }

extension UserRoleInfo on UserRole {
  String get title {
    switch (this) {
      case UserRole.guest:
        return 'Гость';
      case UserRole.admin:
        return 'Администратор';
      case UserRole.chef:
        return 'Шеф-повар';
      case UserRole.waiter:
        return 'Официант';
      case UserRole.cook:
        return 'Повар';
      case UserRole.bartender:
        return 'Бармен';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.guest:
        return Icons.person;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.chef:
        return Icons.restaurant_menu;
      case UserRole.waiter:
        return Icons.room_service;
      case UserRole.cook:
        return Icons.soup_kitchen;
      case UserRole.bartender:
        return Icons.local_bar;
    }
  }

  bool get isStaff => this != UserRole.guest;

  /// Только администратор: персонал, столы, профиль ресторана, отчёты.
  bool get canManage => this == UserRole.admin;

  /// Меню может менять администратор и шеф-повар.
  bool get canEditMenu => this == UserRole.admin || this == UserRole.chef;

  /// Работа с залом: столы, брони, заказы гостей.
  bool get canServe =>
      this == UserRole.admin || this == UserRole.chef || this == UserRole.waiter;

  /// Кухня и бар: видят заказы и меняют статус «готовится / готово».
  bool get canCook =>
      this == UserRole.admin ||
      this == UserRole.chef ||
      this == UserRole.cook ||
      this == UserRole.bartender;
}

/// Роли, которые администратор может выдать сотруднику.
const staffRoles = [
  UserRole.waiter,
  UserRole.cook,
  UserRole.chef,
  UserRole.bartender,
  UserRole.admin,
];

class AppUser {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? restaurantId; // у гостя null
  final String salt;
  final String passwordHash;
  final List<String> favoriteRestaurantIds;

  String get fullName => name;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.restaurantId,
    required this.salt,
    required this.passwordHash,
    this.favoriteRestaurantIds = const [],
  });

  AppUser copyWith({List<String>? favoriteRestaurantIds}) => AppUser(
        id: id,
        name: name,
        phone: phone,
        role: role,
        restaurantId: restaurantId,
        salt: salt,
        passwordHash: passwordHash,
        favoriteRestaurantIds:
            favoriteRestaurantIds ?? this.favoriteRestaurantIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role.name,
        'restaurantId': restaurantId,
        'salt': salt,
        'passwordHash': passwordHash,
        'favoriteRestaurantIds': favoriteRestaurantIds,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.guest,
      ),
      restaurantId: json['restaurantId'] as String?,
      salt: json['salt'] as String,
      passwordHash: json['passwordHash'] as String,
      favoriteRestaurantIds:
          ((json['favoriteRestaurantIds'] as List<dynamic>?) ?? const [])
              .whereType<String>()
              .toList(),
    );
  }
}

/// Результат регистрации или входа: либо пользователь, либо текст ошибки.
class AuthResult {
  final AppUser? user;
  final String? error;
  final String? verificationPhone;

  const AuthResult.ok(AppUser this.user)
      : error = null,
        verificationPhone = null;
  const AuthResult.fail(String this.error)
      : user = null,
        verificationPhone = null;
  const AuthResult.verificationRequired(this.verificationPhone)
      : user = null,
        error = null;

  bool get isOk => user != null;
  bool get requiresPhoneVerification => verificationPhone != null;
}
