import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/service_entry.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';

abstract class JournalEvent {}

class EntryAdded extends JournalEvent {
  final ServiceEntry entry;
  EntryAdded(this.entry);
}

class EntryRemoved extends JournalEvent {
  final String id;
  EntryRemoved(this.id);
}

class EntryResolvedToggled extends JournalEvent {
  final String id;
  EntryResolvedToggled(this.id);
}

class SyncRequested extends JournalEvent {}

class JournalState {
  final List<ServiceEntry> entries;
  final bool syncing;
  final String? message;
  final DateTime? lastSync;

  const JournalState({
    required this.entries,
    this.syncing = false,
    this.message,
    this.lastSync,
  });

  JournalState copyWith({
    List<ServiceEntry>? entries,
    bool? syncing,
    String? message,
    bool clearMessage = false,
    DateTime? lastSync,
  }) {
    return JournalState(
      entries: entries ?? this.entries,
      syncing: syncing ?? this.syncing,
      message: clearMessage ? null : (message ?? this.message),
      lastSync: lastSync ?? this.lastSync,
    );
  }

  int get todayCount {
    final now = DateTime.now();
    return entries
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .length;
  }

  int get unresolvedCount => entries.where((e) => !e.resolved).length;
  int get unsyncedCount => entries.where((e) => !e.synced).length;
}

class JournalBloc extends Bloc<JournalEvent, JournalState> {
  JournalBloc(StorageService storage, ApiClient api)
      : _storage = storage,
        _api = api,
        super(JournalState(
          entries: _sorted(storage.loadEntries()),
          lastSync: storage.loadLastSync(),
        )) {
    on<EntryAdded>(_onAdded);
    on<EntryRemoved>(_onRemoved);
    on<EntryResolvedToggled>(_onToggled);
    on<SyncRequested>(_onSync);
  }

  final StorageService _storage;
  final ApiClient _api;

  static List<ServiceEntry> _sorted(List<ServiceEntry> list) {
    final copy = [...list];
    copy.sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  static bool _sameContent(ServiceEntry a, ServiceEntry b) =>
      a.title == b.title &&
      a.description == b.description &&
      a.workerName == b.workerName &&
      a.workerRole == b.workerRole &&
      a.category == b.category &&
      a.date.isAtSameMomentAs(b.date) &&
      a.resolved == b.resolved;

  Future<void> _onAdded(EntryAdded event, Emitter<JournalState> emit) async {
    final list = _sorted([...state.entries, event.entry]);
    await _storage.saveEntries(list);
    emit(state.copyWith(entries: list));
  }

  Future<void> _onRemoved(
      EntryRemoved event, Emitter<JournalState> emit) async {
    final list = state.entries.where((e) => e.id != event.id).toList();
    await _storage.saveEntries(list);
    emit(state.copyWith(entries: list));
  }

  Future<void> _onToggled(
      EntryResolvedToggled event, Emitter<JournalState> emit) async {
    final list = state.entries
        .map((e) => e.id == event.id ? e.copyWith(resolved: !e.resolved) : e)
        .toList();
    await _storage.saveEntries(list);
    emit(state.copyWith(entries: list));
  }

  Future<void> _onSync(SyncRequested event, Emitter<JournalState> emit) async {
    if (state.syncing) return;

    final pending = state.entries.where((e) => !e.synced).toList();
    if (pending.isEmpty) {
      emit(state.copyWith(clearMessage: true));
      emit(state.copyWith(message: 'Все записи уже отправлены'));
      return;
    }

    emit(state.copyWith(syncing: true, clearMessage: true));
    try {
      await _api.uploadEntries(pending);

      final uploadedById = {for (final entry in pending) entry.id: entry};
      final updated = state.entries.map((entry) {
        final uploaded = uploadedById[entry.id];
        return uploaded != null && _sameContent(entry, uploaded)
            ? entry.copyWith(synced: true)
            : entry;
      }).toList();
      final now = DateTime.now();
      await _storage.saveEntries(updated);
      await _storage.saveLastSync(now);

      emit(state.copyWith(
        entries: updated,
        syncing: false,
        lastSync: now,
        message: 'Отправлено записей: ${pending.length}',
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(syncing: false, message: e.message));
    } on TimeoutException {
      emit(state.copyWith(
          syncing: false, message: 'Сервер не отвечает. Проверьте интернет'));
    } catch (_) {
      emit(
          state.copyWith(syncing: false, message: 'Нет соединения с сервером'));
    }
  }
}
