import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/app_repository.dart';

/// Хранит репозиторий и сообщает экранам, что данные изменились.
/// Состояние — просто счётчик изменений: каждое действие увеличивает его,
/// и все экраны, которые «смотрят» на cubit, перерисовываются.
class DataCubit extends Cubit<int> {
  DataCubit(this.repo) : super(0);

  final AppRepository repo;

  /// Выполнить действие над данными и обновить экраны.
  Future<T> run<T>(Future<T> Function(AppRepository repo) action) async {
    final result = await action(repo);
    emit(state + 1);
    return result;
  }
}

extension DataContext on BuildContext {
  /// Репозиторий с подпиской: экран обновляется при любом изменении данных.
  AppRepository get repo =>
      BlocProvider.of<DataCubit>(this, listen: true).repo;

  /// Для вызова действий (без подписки).
  DataCubit get data => BlocProvider.of<DataCubit>(this);
}
