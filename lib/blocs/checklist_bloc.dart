import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/checklist_item.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';

abstract class ChecklistEvent {}

class ChecklistItemToggled extends ChecklistEvent {
  final String itemId;
  final String workerName;
  ChecklistItemToggled(this.itemId, this.workerName);
}

class ChecklistReset extends ChecklistEvent {}

class ChecklistState {
  final List<ChecklistItem> items;
  const ChecklistState(this.items);

  List<ChecklistItem> itemsOf(ChecklistType type) =>
      items.where((i) => i.type == type).toList();

  int doneCount(ChecklistType type) =>
      itemsOf(type).where((i) => i.done).length;

  double progress(ChecklistType type) {
    final total = itemsOf(type).length;
    return total == 0 ? 0.0 : doneCount(type) / total;
  }
}

class ChecklistBloc extends Bloc<ChecklistEvent, ChecklistState> {
  ChecklistBloc(StorageService storage)
      : _storage = storage,
        super(ChecklistState(_loadToday(storage))) {
    on<ChecklistItemToggled>((event, emit) async {
      final items = state.items.map((item) {
        if (item.id != event.itemId) return item;
        return item.done ? item.reset() : item.markDone(event.workerName);
      }).toList();
      await _save(items);
      emit(ChecklistState(items));
    });

    on<ChecklistReset>((event, emit) async {
      final items = state.items.map((i) => i.reset()).toList();
      await _save(items);
      emit(ChecklistState(items));
    });
  }

  final StorageService _storage;

  Future<void> _save(List<ChecklistItem> items) =>
      _storage.saveChecklist(items, dayKeyFormat.format(DateTime.now()));

  static List<ChecklistItem> _loadToday(StorageService storage) {
    final today = dayKeyFormat.format(DateTime.now());
    final saved = storage.loadChecklist();

    if (saved == null) {
      final items = ChecklistItem.defaults();
      storage.saveChecklist(items, today);
      return items;
    }
    if (storage.loadChecklistDay() != today) {
      final items = saved.map((i) => i.reset()).toList();
      storage.saveChecklist(items, today);
      return items;
    }
    return saved;
  }
}
