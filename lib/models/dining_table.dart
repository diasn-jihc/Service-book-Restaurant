import 'package:flutter/material.dart';

enum TableZone { hall, cabin, terrace }

extension TableZoneInfo on TableZone {
  String get title {
    switch (this) {
      case TableZone.hall:
        return 'Зал';
      case TableZone.cabin:
        return 'Кабинка';
      case TableZone.terrace:
        return 'Терраса';
    }
  }

  String get plural {
    switch (this) {
      case TableZone.hall:
        return 'Зал';
      case TableZone.cabin:
        return 'Кабинки';
      case TableZone.terrace:
        return 'Терраса';
    }
  }

  IconData get icon {
    switch (this) {
      case TableZone.hall:
        return Icons.table_restaurant;
      case TableZone.cabin:
        return Icons.meeting_room;
      case TableZone.terrace:
        return Icons.deck;
    }
  }
}

/// Состояние стола «прямо сейчас».
enum TableStatus { free, reserved, occupied }

extension TableStatusInfo on TableStatus {
  String get title {
    switch (this) {
      case TableStatus.free:
        return 'Свободен';
      case TableStatus.reserved:
        return 'Забронирован';
      case TableStatus.occupied:
        return 'Занят';
    }
  }
}

class DiningTable {
  final String id;
  final String restaurantId;
  final int number;
  final int seats;
  final TableZone zone;
  final bool occupied; // гости сидят прямо сейчас
  final int guests;
  final DateTime? since;

  const DiningTable({
    required this.id,
    required this.restaurantId,
    required this.number,
    required this.seats,
    required this.zone,
    this.occupied = false,
    this.guests = 0,
    this.since,
  });

  DiningTable copyWith({int? number, int? seats, TableZone? zone}) {
    return DiningTable(
      id: id,
      restaurantId: restaurantId,
      number: number ?? this.number,
      seats: seats ?? this.seats,
      zone: zone ?? this.zone,
      occupied: occupied,
      guests: guests,
      since: since,
    );
  }

  /// Посадить гостей.
  DiningTable seated(int guestsCount) => DiningTable(
        id: id,
        restaurantId: restaurantId,
        number: number,
        seats: seats,
        zone: zone,
        occupied: true,
        guests: guestsCount,
        since: DateTime.now(),
      );

  /// Освободить стол.
  DiningTable freed() => DiningTable(
        id: id,
        restaurantId: restaurantId,
        number: number,
        seats: seats,
        zone: zone,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurantId': restaurantId,
        'number': number,
        'seats': seats,
        'zone': zone.name,
        'occupied': occupied,
        'guests': guests,
        'since': since?.toIso8601String(),
      };

  factory DiningTable.fromJson(Map<String, dynamic> json) {
    final sinceText = json['since'] as String?;
    return DiningTable(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      number: json['number'] as int,
      seats: json['seats'] as int,
      zone: TableZone.values.firstWhere(
        (z) => z.name == json['zone'],
        orElse: () => TableZone.hall,
      ),
      occupied: (json['occupied'] as bool?) ?? false,
      guests: (json['guests'] as int?) ?? 0,
      since: sinceText == null ? null : DateTime.tryParse(sinceText),
    );
  }
}
