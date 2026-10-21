import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/checklist_item.dart';
import '../models/service_entry.dart';
import '../models/worker.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  AppState(this._storage, this._api);

  final StorageService _storage;
  final ApiClient _api;

  List<ServiceEntry> _entries = [];
  List<ChecklistItem> _checklist = [];
  bool loading = true;
  bool syncing = false;
  DateTime? lastSync;

  List<ServiceEntry> get entries => List.unmodifiable(_entries);
  List<ChecklistItem> get checklist => List.unmodifiable(_checklist);

  List<ChecklistItem> checklistOf(ChecklistType type) =>
      _checklist.where((i) => i.type == type).toList();

  double progressOf(ChecklistType type) {
    final items = checklistOf(type);
    if (items.isEmpty) return 0;
    return items.where((i) => i.done).length / items.length;
  }

  int doneCountOf(ChecklistType type) =>
      checklistOf(type).where((i) => i.done).length;

  int get todayCount {
    final now = DateTime.now();
    return _entries
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .length;
  }

  int get unresolvedCount => _entries.where((e) => !e.resolved).length;
  int get unsyncedCount => _entries.where((e) => !e.synced).length;

  ServiceEntry? entryById(String id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  String _dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> load() async {
    _entries = _storage.loadEntries();
    _sortEntries();

    final saved = _storage.loadChecklist();
    final savedDay = _storage.loadChecklistDay();
    final today = _dayKey(DateTime.now());

    if (saved == null) {
      _checklist = ChecklistItem.defaults();
    } else if (savedDay != today) {
      _checklist = saved.map((i) => i.reset()).toList();
    } else {
      _checklist = saved;
    }
    await _storage.saveChecklist(_checklist, today);

    lastSync = _storage.loadLastSync();
    loading = false;
    notifyListeners();
  }

  void _sortEntries() => _entries.sort((a, b) => b.date.compareTo(a.date));

  Future<void> _persistEntries() => _storage.saveEntries(_entries);

  Future<void> addEntry({
    required String title,
    required String description,
    required String responsible,
    required WorkerRole responsibleRole,
    required EntryCategory category,
    required DateTime date,
    required bool resolved,
  }) async {
    _entries.add(ServiceEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      description: description,
      workerName: responsible,
      workerRole: responsibleRole,
      category: category,
      date: date,
      resolved: resolved,
    ));
    _sortEntries();
    notifyListeners();
    await _persistEntries();
  }

  Future<void> toggleResolved(String id) async {
    _entries = _entries
        .map((e) => e.id == id ? e.copyWith(resolved: !e.resolved) : e)
        .toList();
    notifyListeners();
    await _persistEntries();
  }

  Future<void> deleteEntry(String id) async {
    _entries = _entries.where((e) => e.id != id).toList();
    notifyListeners();
    await _persistEntries();
  }

  Future<void> toggleChecklistItem(String id) async {
    _checklist = _checklist
        .map((i) => i.id == id
            ? (i.done ? i.reset() : i.markDone(''))
            : i)
        .toList();
    notifyListeners();
    await _storage.saveChecklist(_checklist, _dayKey(DateTime.now()));
  }

  Future<void> resetChecklist() async {
    _checklist = _checklist.map((i) => i.reset()).toList();
    notifyListeners();
    await _storage.saveChecklist(_checklist, _dayKey(DateTime.now()));
  }

  Future<String> sync() async {
    final pending = _entries.where((e) => !e.synced).toList();
    if (pending.isEmpty) return 'Все записи уже отправлены';

    syncing = true;
    notifyListeners();
    try {
      await _api.uploadEntries(pending);
      final ids = pending.map((e) => e.id).toSet();
      _entries = _entries
          .map((e) => ids.contains(e.id) ? e.copyWith(synced: true) : e)
          .toList();
      lastSync = DateTime.now();
      await _persistEntries();
      await _storage.saveLastSync(lastSync!);
      return 'Отправлено записей: ${pending.length}';
    } on ApiException catch (e) {
      return e.message;
    } on TimeoutException {
      return 'Сервер не отвечает. Проверьте интернет';
    } catch (_) {
      return 'Нет соединения с сервером';
    } finally {
      syncing = false;
      notifyListeners();
    }
  }
}
