enum ChecklistType { opening, closing }

/// Пункт чек-листа ресторана. Отметка считается выполненной только сегодня,
/// поэтому на следующий день список «обнуляется» сам.
class ChecklistItem {
  final String id;
  final String restaurantId;
  final String title;
  final ChecklistType type;
  final String? doneBy;
  final DateTime? doneAt;

  const ChecklistItem({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.type,
    this.doneBy,
    this.doneAt,
  });

  bool get doneToday {
    final at = doneAt;
    if (at == null) return false;
    final now = DateTime.now();
    return at.year == now.year && at.month == now.month && at.day == now.day;
  }

  /// Compatibility alias for screens that only need the current day's state.
  bool get done => doneToday;

  ChecklistItem markDone(String workerName) => ChecklistItem(
        id: id,
        restaurantId: restaurantId,
        title: title,
        type: type,
        doneBy: workerName,
        doneAt: DateTime.now(),
      );

  ChecklistItem reset() => ChecklistItem(
        id: id,
        restaurantId: restaurantId,
        title: title,
        type: type,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurantId': restaurantId,
        'title': title,
        'type': type.name,
        'doneBy': doneBy,
        'doneAt': doneAt?.toIso8601String(),
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    final doneText = json['doneAt'] as String?;
    return ChecklistItem(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      title: json['title'] as String,
      type: ChecklistType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ChecklistType.opening,
      ),
      doneBy: json['doneBy'] as String?,
      doneAt: doneText == null ? null : DateTime.tryParse(doneText),
    );
  }

  /// Стандартный чек-лист для нового ресторана.
  static List<ChecklistItem> defaultsFor(String restaurantId) {
    ChecklistItem item(String key, String title, ChecklistType type) =>
        ChecklistItem(
          id: '${restaurantId}_$key',
          restaurantId: restaurantId,
          title: title,
          type: type,
        );

    return [
      item('o1', 'Проверить чистоту зала и кухни', ChecklistType.opening),
      item('o2', 'Включить вытяжку и оборудование', ChecklistType.opening),
      item('o3', 'Проверить температуру холодильников', ChecklistType.opening),
      item('o4', 'Проверить сроки годности продуктов', ChecklistType.opening),
      item('o5', 'Накрыть столы и проверить посуду', ChecklistType.opening),
      item('o6', 'Сверить кассу и терминал', ChecklistType.opening),
      item('c1', 'Вынести мусор', ChecklistType.closing),
      item('c2', 'Вымыть и продезинфицировать поверхности', ChecklistType.closing),
      item('c3', 'Выключить плиты, фритюр и вытяжку', ChecklistType.closing),
      item('c4', 'Убрать продукты в холодильники', ChecklistType.closing),
      item('c5', 'Закрыть кассовую смену', ChecklistType.closing),
      item('c6', 'Закрыть двери и включить сигнализацию', ChecklistType.closing),
    ];
  }

  /// Default checklist used by the local checklist provider.
  static List<ChecklistItem> defaults({String restaurantId = 'default'}) =>
      defaultsFor(restaurantId);
}
