import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Сколько длится бронь стола.
const reservationDuration = Duration(minutes: 120);

enum ReservationStatus { pending, confirmed, seated, completed, cancelled }

extension ReservationStatusInfo on ReservationStatus {
  String get title {
    switch (this) {
      case ReservationStatus.pending:
        return 'Ожидает';
      case ReservationStatus.confirmed:
        return 'Подтверждена';
      case ReservationStatus.seated:
        return 'Гости за столом';
      case ReservationStatus.completed:
        return 'Завершена';
      case ReservationStatus.cancelled:
        return 'Отменена';
    }
  }

  Color get color {
    switch (this) {
      case ReservationStatus.pending:
        return reservedColor;
      case ReservationStatus.confirmed:
        return freeColor;
      case ReservationStatus.seated:
        return skyColor;
      case ReservationStatus.completed:
        return Colors.white54;
      case ReservationStatus.cancelled:
        return busyColor;
    }
  }

  /// Бронь ещё «живая» и занимает стол.
  bool get isActive =>
      this == ReservationStatus.pending ||
      this == ReservationStatus.confirmed ||
      this == ReservationStatus.seated;
}

class Reservation {
  final String id;
  final String restaurantId;
  final String tableId;
  final String userId;
  final String guestName;
  final String phone;
  final DateTime start;
  final int guests;
  final ReservationStatus status;
  final String comment;
  final DateTime createdAt;

  const Reservation({
    required this.id,
    required this.restaurantId,
    required this.tableId,
    required this.userId,
    required this.guestName,
    required this.phone,
    required this.start,
    required this.guests,
    required this.status,
    required this.comment,
    required this.createdAt,
  });

  DateTime get end => start.add(reservationDuration);

  Reservation copyWith({ReservationStatus? status}) {
    return Reservation(
      id: id,
      restaurantId: restaurantId,
      tableId: tableId,
      userId: userId,
      guestName: guestName,
      phone: phone,
      start: start,
      guests: guests,
      status: status ?? this.status,
      comment: comment,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurantId': restaurantId,
        'tableId': tableId,
        'userId': userId,
        'guestName': guestName,
        'phone': phone,
        'start': start.toIso8601String(),
        'guests': guests,
        'status': status.name,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      tableId: json['tableId'] as String,
      userId: json['userId'] as String,
      guestName: (json['guestName'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      start: DateTime.parse(json['start'] as String),
      guests: json['guests'] as int,
      status: ReservationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ReservationStatus.pending,
      ),
      comment: (json['comment'] as String?) ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
