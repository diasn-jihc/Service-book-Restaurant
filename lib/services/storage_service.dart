import 'dart:convert';

import '../models/checklist_item.dart';
import '../models/service_entry.dart';
import '../models/worker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/password.dart';

/// Тонкая обёртка над SharedPreferences: списки в JSON и простые значения.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  List<T> readList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return []; // данные повреждены — начинаем с чистого листа
    }
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> list) {
    return _prefs.setString(key, jsonEncode(list));
  }

  String? readString(String key) => _prefs.getString(key);
  Future<void> writeString(String key, String value) =>
      _prefs.setString(key, value);

  int? readInt(String key) => _prefs.getInt(key);
  Future<void> writeInt(String key, int value) => _prefs.setInt(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  List<ServiceEntry> loadEntries() => readList('entries', ServiceEntry.fromJson);

  Future<void> saveEntries(List<ServiceEntry> entries) => writeList(
        'entries',
        entries.map((entry) => entry.toJson()).toList(),
      );

  List<ChecklistItem>? loadChecklist() {
    if (!_prefs.containsKey('checklist')) return null;
    return readList('checklist', ChecklistItem.fromJson);
  }

  Future<void> saveChecklist(List<ChecklistItem> items, String dayKey) async {
    await writeList('checklist', items.map((item) => item.toJson()).toList());
    await writeString('checklist_day', dayKey);
  }

  String? loadChecklistDay() => readString('checklist_day');

  DateTime? loadLastSync() {
    final value = readString('last_sync');
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> saveLastSync(DateTime value) =>
      writeString('last_sync', value.toIso8601String());

  int loadAccentIndex() => readInt('accent') ?? 0;
  Future<void> saveAccentIndex(int index) => writeInt('accent', index);

  int loadGuests() => readInt('guests') ?? 0;
  Future<void> saveGuests(int value) => writeInt('guests', value);

  List<Worker> loadWorkers() => readList('workers', Worker.fromJson);
  Future<void> saveWorkers(List<Worker> workers) => writeList(
        'workers', workers.map((worker) => worker.toJson()).toList());

  String _passwordKey(String phone) => 'password_$phone';
  bool hasPassword(String phone) => _prefs.containsKey(_passwordKey(phone));
  bool verifyPassword(String phone, String password) {
    final stored = readString(_passwordKey(phone));
    final separator = stored?.indexOf(':') ?? -1;
    if (stored == null || separator < 1) return false;
    final salt = stored.substring(0, separator);
    return stored.substring(separator + 1) == hashPassword(password, salt);
  }
  Future<void> savePassword(String phone, String password) async {
    final salt = makeSalt();
    await writeString(_passwordKey(phone), '$salt:${hashPassword(password, salt)}');
  }
  Future<void> clearPassword(String phone) => remove(_passwordKey(phone));
  Future<void> movePassword(String from, String to) async {
    final value = readString(_passwordKey(from));
    if (value == null) return;
    await savePassword(to, value);
    await clearPassword(from);
  }
  Future<void> upgradePasswordHash(String phone, String password) async {
    final stored = readString(_passwordKey(phone));
    if (stored != null && !stored.contains(':')) {
      await savePassword(phone, password);
    }
  }
}
