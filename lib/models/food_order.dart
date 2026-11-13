import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum OrderStatus { fresh, cooking, ready, served, paid, cancelled }

extension OrderStatusInfo on OrderStatus {
  String get title {
    switch (this) {
      case OrderStatus.fresh:
        return 'Новый';
      case OrderStatus.cooking:
        return 'Готовится';
      case OrderStatus.ready:
        return 'Готов';
      case OrderStatus.served:
        return 'Подан';
      case OrderStatus.paid:
        return 'Оплачен';
      case OrderStatus.cancelled:
        return 'Отменён';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.fresh:
        return skyColor;
      case OrderStatus.cooking:
        return reservedColor;
      case OrderStatus.ready:
        return freeColor;
      case OrderStatus.served:
        return const Color(0xFFA78BFA);
      case OrderStatus.paid:
        return Colors.white54;
      case OrderStatus.cancelled:
        return busyColor;
    }
  }

  /// Заказ ещё в работе.
  bool get isOpen => this != OrderStatus.paid && this != OrderStatus.cancelled;

  /// Следующий статус, null если дальше некуда.
  OrderStatus? get next {
    switch (this) {
      case OrderStatus.fresh:
        return OrderStatus.cooking;
      case OrderStatus.cooking:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.served;
      case OrderStatus.served:
        return OrderStatus.paid;
      case OrderStatus.paid:
      case OrderStatus.cancelled:
        return null;
    }
  }

  /// Подпись кнопки, которая переводит заказ дальше.
  String get nextLabel {
    switch (this) {
      case OrderStatus.fresh:
        return 'Взять в работу';
      case OrderStatus.cooking:
        return 'Готово';
      case OrderStatus.ready:
        return 'Подано';
      case OrderStatus.served:
        return 'Оплачено';
      case OrderStatus.paid:
      case OrderStatus.cancelled:
        return '';
    }
  }
}

class OrderItem {
  final String dishId;
  final String name;
  final int price;
  final int qty;

  const OrderItem({
    required this.dishId,
    required this.name,
    required this.price,
    required this.qty,
  });

  int get sum => price * qty;

  Map<String, dynamic> toJson() =>
      {'dishId': dishId, 'name': name, 'price': price, 'qty': qty};

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        dishId: json['dishId'] as String,
        name: json['name'] as String,
        price: json['price'] as int,
        qty: json['qty'] as int,
      );
}

/// Заказ: из зала (официант) или предзаказ гостя к брони.
class FoodOrder {
  final String id;
  final String restaurantId;
  final String? tableId;
  final String? reservationId; // не null — это предзаказ
  final String createdById;
  final String createdByName;
  final List<OrderItem> items;
  final OrderStatus status;
  final String comment;
  final DateTime createdAt;
  final DateTime? forTime; // к какому времени готовить предзаказ
  final DateTime? paidAt;

  const FoodOrder({
    required this.id,
    required this.restaurantId,
    required this.tableId,
    required this.reservationId,
    required this.createdById,
    required this.createdByName,
    required this.items,
    required this.status,
    required this.comment,
    required this.createdAt,
    this.forTime,
    this.paidAt,
  });

  int get total => items.fold(0, (sum, item) => sum + item.sum);
  int get itemsCount => items.fold(0, (sum, item) => sum + item.qty);
  bool get isPreorder => reservationId != null;

  FoodOrder copyWith({OrderStatus? status, DateTime? paidAt}) {
    return FoodOrder(
      id: id,
      restaurantId: restaurantId,
      tableId: tableId,
      reservationId: reservationId,
      createdById: createdById,
      createdByName: createdByName,
      items: items,
      status: status ?? this.status,
      comment: comment,
      createdAt: createdAt,
      forTime: forTime,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurantId': restaurantId,
        'tableId': tableId,
        'reservationId': reservationId,
        'createdById': createdById,
        'createdByName': createdByName,
        'items': items.map((i) => i.toJson()).toList(),
        'status': status.name,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'forTime': forTime?.toIso8601String(),
        'paidAt': paidAt?.toIso8601String(),
      };

  factory FoodOrder.fromJson(Map<String, dynamic> json) {
    final forText = json['forTime'] as String?;
    final paidText = json['paidAt'] as String?;
    return FoodOrder(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      tableId: json['tableId'] as String?,
      reservationId: json['reservationId'] as String?,
      createdById: json['createdById'] as String,
      createdByName: (json['createdByName'] as String?) ?? '',
      items: ((json['items'] as List<dynamic>?) ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: OrderStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => OrderStatus.fresh,
      ),
      comment: (json['comment'] as String?) ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      forTime: forText == null ? null : DateTime.tryParse(forText),
      paidAt: paidText == null ? null : DateTime.tryParse(paidText),
    );
  }
}
