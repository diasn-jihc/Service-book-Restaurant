import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';

abstract class ThemeEvent {}

class AccentSelected extends ThemeEvent {
  final int index;
  AccentSelected(this.index);
}

class ThemeState {
  final int accentIndex; // номер цвета в accentOptions
  const ThemeState(this.accentIndex);
}

/// Меняет цвет интерфейса и запоминает выбор.
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc(this._store) : super(ThemeState(_load(_store))) {
    on<AccentSelected>((event, emit) async {
      await _store.writeInt('accent', event.index);
      emit(ThemeState(event.index));
    });
  }

  final StorageService _store;

  static int _load(StorageService store) {
    final saved = store.readInt('accent') ?? 0;
    return saved >= 0 && saved < accentOptions.length ? saved : 0;
  }
}
