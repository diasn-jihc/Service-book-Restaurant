import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cities.dart';
import '../services/storage_service.dart';

/// Выбранный город (запоминается на устройстве).
class CityCubit extends Cubit<String> {
  CityCubit(this._store) : super(_store.readString('city') ?? defaultCity);

  final StorageService _store;

  void select(String city) {
    emit(city);
    _store.writeString('city', city);
  }
}
