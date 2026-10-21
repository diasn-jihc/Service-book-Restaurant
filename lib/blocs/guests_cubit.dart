import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/storage_service.dart';

class GuestsCubit extends Cubit<int> {
  GuestsCubit(StorageService storage)
      : _storage = storage,
        super(storage.loadGuests());

  final StorageService _storage;

  void _set(int value) {
    emit(value);
    _storage.saveGuests(value);
  }

  void add() => _set(state + 1);

  void remove() {
    if (state > 0) _set(state - 1);
  }

  void reset() => _set(0);
}
