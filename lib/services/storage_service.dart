import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checklist_item.dart';
import '../models/service_entry.dart';
import '../models/worker.dart';

class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  List<T>? _readList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> list) {
    return _prefs.setString(key, jsonEncode(list));
  }

  Worker? loadUser() {
    final raw = _prefs.getString('user');
    if (raw == null) return null;
    try {
      return Worker.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(Worker user) =>
      _prefs.setString('user', jsonEncode(user.toJson()));

  Future<void> clearUser() => _prefs.remove('user');

  String _passwordKey(String phone) => 'password_${sha256.convert(utf8.encode(phone))}';

  Future<void> savePassword(String phone, String password) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final digest = sha256.convert(utf8.encode('$salt:$password')).toString();
    await _prefs.setString(_passwordKey(phone), '$salt:$digest');
  }

  bool verifyPassword(String phone, String password) {
    final saved = _prefs.getString(_passwordKey(phone));
    if (saved == null) return false;
    final separator = saved.indexOf(':');
    if (separator < 0) return false;
    final salt = saved.substring(0, separator);
    final digest = saved.substring(separator + 1);
    return digest == sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  bool hasPassword(String phone) => _prefs.containsKey(_passwordKey(phone));

  Future<void> movePassword(String oldPhone, String newPhone) async {
    if (oldPhone == newPhone) return;
    final saved = _prefs.getString(_passwordKey(oldPhone));
    if (saved == null) return;
    await _prefs.setString(_passwordKey(newPhone), saved);
    await _prefs.remove(_passwordKey(oldPhone));
  }

  List<Worker> loadWorkers() => _readList('workers', Worker.fromJson) ?? [];

  Future<void> saveWorkers(List<Worker> workers) =>
      _writeList('workers', workers.map((w) => w.toJson()).toList());

  List<ServiceEntry> loadEntries() =>
      _readList('entries', ServiceEntry.fromJson) ?? [];

  Future<void> saveEntries(List<ServiceEntry> entries) =>
      _writeList('entries', entries.map((e) => e.toJson()).toList());

  List<ChecklistItem>? loadChecklist() =>
      _readList('checklist', ChecklistItem.fromJson);

  String? loadChecklistDay() => _prefs.getString('checklist_day');

  Future<void> saveChecklist(List<ChecklistItem> items, String day) async {
    await _writeList('checklist', items.map((i) => i.toJson()).toList());
    await _prefs.setString('checklist_day', day);
  }

  int loadAccentIndex() => _prefs.getInt('accent') ?? 0;
  Future<void> saveAccentIndex(int index) => _prefs.setInt('accent', index);

  int loadGuests() => _prefs.getInt('guests') ?? 0;
  Future<void> saveGuests(int value) => _prefs.setInt('guests', value);

  DateTime? loadLastSync() {
    final raw = _prefs.getString('last_sync');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> saveLastSync(DateTime value) =>
      _prefs.setString('last_sync', value.toIso8601String());
}
