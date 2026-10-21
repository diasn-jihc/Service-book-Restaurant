import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/worker.dart';
import '../services/storage_service.dart';

abstract class WorkersEvent {}

class WorkerAdded extends WorkersEvent {
  final Worker worker;
  WorkerAdded(this.worker);
}

class WorkerRemoved extends WorkersEvent {
  final String id;
  WorkerRemoved(this.id);
}

class WorkerUpdated extends WorkersEvent {
  final Worker worker;
  final String previousPhone;
  WorkerUpdated(this.worker, this.previousPhone);
}

class WorkersState {
  final List<Worker> workers;
  const WorkersState(this.workers);
}

class WorkersBloc extends Bloc<WorkersEvent, WorkersState> {
  WorkersBloc(StorageService storage)
      : _storage = storage,
        super(WorkersState(storage.loadWorkers())) {
    on<WorkerAdded>((event, emit) async {
      final list = [...state.workers, event.worker];
      await _storage.saveWorkers(list);
      emit(WorkersState(list));
    });

    on<WorkerRemoved>((event, emit) async {
      final removed = state.workers.where((worker) => worker.id == event.id);
      final list = state.workers.where((w) => w.id != event.id).toList();
      await _storage.saveWorkers(list);
      if (removed.isNotEmpty) {
        await _storage.clearPassword(removed.first.phone);
      }
      emit(WorkersState(list));
    });

    on<WorkerUpdated>((event, emit) async {
      final list = state.workers
          .map((worker) => worker.id == event.worker.id ? event.worker : worker)
          .toList();
      await _storage.movePassword(event.previousPhone, event.worker.phone);
      await _storage.saveWorkers(list);
      emit(WorkersState(list));
    });
  }

  final StorageService _storage;
}
