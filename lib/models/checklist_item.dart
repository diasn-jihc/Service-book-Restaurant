enum ChecklistType { opening, closing }

class ChecklistItem {
  final String id;
  final String title;
  final ChecklistType type;
  final String? doneBy;
  final DateTime? doneAt;

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.type,
    this.doneBy,
    this.doneAt,
  });

  bool get done => doneAt != null;

  ChecklistItem markDone(String workerName) => ChecklistItem(
        id: id,
        title: title,
        type: type,
        doneBy: workerName,
        doneAt: DateTime.now(),
      );

  ChecklistItem reset() => ChecklistItem(id: id, title: title, type: type);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'doneBy': doneBy,
        'doneAt': doneAt?.toIso8601String(),
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    final doneAtText = json['doneAt'] as String?;
    return ChecklistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      type: ChecklistType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ChecklistType.opening,
      ),
      doneBy: json['doneBy'] as String?,
      doneAt: doneAtText == null ? null : DateTime.tryParse(doneAtText),
    );
  }

  static List<ChecklistItem> defaults() => const [
        ChecklistItem(id: 'o1', title: 'Проверить чистоту зала и кухни', type: ChecklistType.opening),
        ChecklistItem(id: 'o2', title: 'Включить вытяжку и оборудование', type: ChecklistType.opening),
        ChecklistItem(id: 'o3', title: 'Проверить температуру холодильников', type: ChecklistType.opening),
        ChecklistItem(id: 'o4', title: 'Проверить сроки годности продуктов', type: ChecklistType.opening),
        ChecklistItem(id: 'o5', title: 'Накрыть столы и проверить посуду', type: ChecklistType.opening),
        ChecklistItem(id: 'o6', title: 'Сверить кассу и терминал', type: ChecklistType.opening),
        ChecklistItem(id: 'c1', title: 'Вынести мусор', type: ChecklistType.closing),
        ChecklistItem(id: 'c2', title: 'Вымыть и продезинфицировать поверхности', type: ChecklistType.closing),
        ChecklistItem(id: 'c3', title: 'Выключить плиты, фритюр и вытяжку', type: ChecklistType.closing),
        ChecklistItem(id: 'c4', title: 'Убрать продукты в холодильники', type: ChecklistType.closing),
        ChecklistItem(id: 'c5', title: 'Закрыть кассовую смену', type: ChecklistType.closing),
        ChecklistItem(id: 'c6', title: 'Закрыть двери и включить сигнализацию', type: ChecklistType.closing),
      ];
}
