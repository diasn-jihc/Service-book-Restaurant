import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/storage_service.dart';

abstract class ThemeEvent {}

class AccentSelected extends ThemeEvent {
  final int index;
  AccentSelected(this.index);
}

class ThemeState {
  final int accentIndex;
  const ThemeState(this.accentIndex);
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc(StorageService storage)
      : _storage = storage,
        super(ThemeState(storage.loadAccentIndex())) {
    on<AccentSelected>((event, emit) async {
      await _storage.saveAccentIndex(event.index);
      emit(ThemeState(event.index));
    });
  }

  final StorageService _storage;
}
