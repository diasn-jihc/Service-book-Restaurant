import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/app_repository.dart';
import '../models/user.dart';

// ---- события ----
abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String phone;
  final String password;
  LoginRequested(this.phone, this.password);
}

/// После успешной регистрации.
class SessionStarted extends AuthEvent {
  final AppUser user;
  SessionStarted(this.user);
}

class LoggedOut extends AuthEvent {}

// ---- состояние ----
class AuthState {
  final AppUser? user; // null — никто не вошёл
  final String? error; // ошибка входа
  const AuthState({this.user, this.error});

  bool get isLoggedIn => user != null;
}

// ---- блок ----
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(AuthState(user: _repo.restoreSession())) {
    on<LoginRequested>((event, emit) async {
      final result = await _repo.login(event.phone, event.password);
      final user = result.user;
      if (user == null) {
        emit(AuthState(error: result.error));
        return;
      }
      await _repo.saveSession(user.id);
      emit(AuthState(user: user));
    });

    on<SessionStarted>((event, emit) async {
      await _repo.saveSession(event.user.id);
      emit(AuthState(user: event.user));
    });

    on<LoggedOut>((event, emit) async {
      await _repo.clearSession();
      emit(const AuthState());
    });
  }

  final AppRepository _repo;
}
