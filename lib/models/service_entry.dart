import 'package:flutter/material.dart';
import 'worker.dart';

enum EntryCategory { cleaning, equipment, sanitary, supplies, other }

extension EntryCategoryInfo on EntryCategory {
  String get title {
    switch (this) {
      case EntryCategory.cleaning:
        return 'Уборка';
      case EntryCategory.equipment:
        return 'Оборудование';
      case EntryCategory.sanitary:
        return 'Санитария';
      case EntryCategory.supplies:
        return 'Закупки';
      case EntryCategory.other:
        return 'Другое';
    }
  }

  IconData get icon {
    switch (this) {
      case EntryCategory.cleaning:
        return Icons.cleaning_services;
      case EntryCategory.equipment:
        return Icons.kitchen;
      case EntryCategory.sanitary:
        return Icons.health_and_safety;
      case EntryCategory.supplies:
        return Icons.shopping_basket;
      case EntryCategory.other:
        return Icons.more_horiz;
    }
  }
}

class ServiceEntry {
  final String id;
  final String title;
  final String description;
  final String workerName;
  final WorkerRole workerRole;
  final EntryCategory category;
  final DateTime date;
  final bool resolved;
  final bool synced;

  const ServiceEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.workerName,
    required this.workerRole,
    required this.category,
    required this.date,
    this.resolved = true,
    this.synced = false,
  });

  ServiceEntry copyWith({bool? resolved, bool? synced}) {
    return ServiceEntry(
      id: id,
      title: title,
      description: description,
      workerName: workerName,
      workerRole: workerRole,
      category: category,
      date: date,
      resolved: resolved ?? this.resolved,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'workerName': workerName,
        'workerRole': workerRole.name,
        'category': category.name,
        'date': date.toIso8601String(),
        'resolved': resolved,
        'synced': synced,
      };

  factory ServiceEntry.fromJson(Map<String, dynamic> json) {
    return ServiceEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      workerName: (json['workerName'] as String?) ?? '',
      workerRole: WorkerRole.values.firstWhere(
        (r) => r.name == json['workerRole'],
        orElse: () => WorkerRole.waiter,
      ),
      category: EntryCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => EntryCategory.other,
      ),
      date: DateTime.parse(json['date'] as String),
      resolved: (json['resolved'] as bool?) ?? true,
      synced: (json['synced'] as bool?) ?? false,
    );
  }
}
