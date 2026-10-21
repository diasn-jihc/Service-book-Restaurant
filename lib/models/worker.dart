import 'package:flutter/material.dart';

enum WorkerRole { waiter, cook, chef, bartender, administrator, cleaner }

extension WorkerRoleInfo on WorkerRole {
  String get title {
    switch (this) {
      case WorkerRole.waiter:
        return 'Официант';
      case WorkerRole.cook:
        return 'Повар';
      case WorkerRole.chef:
        return 'Шеф-повар';
      case WorkerRole.bartender:
        return 'Бармен';
      case WorkerRole.administrator:
        return 'Администратор';
      case WorkerRole.cleaner:
        return 'Уборщик';
    }
  }

  IconData get icon {
    switch (this) {
      case WorkerRole.waiter:
        return Icons.room_service;
      case WorkerRole.cook:
        return Icons.soup_kitchen;
      case WorkerRole.chef:
        return Icons.restaurant_menu;
      case WorkerRole.bartender:
        return Icons.local_bar;
      case WorkerRole.administrator:
        return Icons.admin_panel_settings;
      case WorkerRole.cleaner:
        return Icons.cleaning_services;
    }
  }
}

class Worker {
  final String id;
  final String fullName;
  final String phone;
  final WorkerRole role;

  const Worker({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'role': role.name,
      };

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      role: WorkerRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => WorkerRole.waiter,
      ),
    );
  }
}
