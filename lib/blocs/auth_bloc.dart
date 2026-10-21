import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/worker.dart';
import '../services/storage_service.dart';

abstract class AuthEvent {}

class UserRegistered extends AuthEvent {
  final Worker user;
  final String password;
  UserRegistered(this.user, this.password);
}

class UserLoggedIn extends AuthEvent {
  final Worker user;
  UserLoggedIn(this.user);
}

class UserProfileUpdated extends AuthEvent {
  final Worker user;
  final String previousPhone;
  UserProfileUpdated(this.user, this.previousPhone);
}

class UserLoggedOut extends AuthEvent {}

class AuthState {
  final Worker? user;
  const AuthState(this.user);

  bool get isLoggedIn => user != null;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(StorageService storage)
      : _storage = storage,
        super(AuthState(storage.loadUser())) {
    on<UserRegistered>((event, emit) async {
      await _storage.savePassword(event.user.phone, event.password);
      await _storage.saveWorkers([
        ..._storage
            .loadWorkers()
            .where((worker) => worker.phone != event.user.phone),
        event.user,
      ]);
      await _storage.saveUser(event.user);
      emit(AuthState(event.user));
    });

    on<UserLoggedIn>((event, emit) async {
      await _storage.saveUser(event.user);
      emit(AuthState(event.user));
    });

    on<UserProfileUpdated>((event, emit) async {
      if (state.user?.id != event.user.id) return;
      await _storage.saveUser(event.user);
      emit(AuthState(event.user));
    });

    on<UserLoggedOut>((event, emit) async {
      await _storage.clearUser();
      emit(const AuthState(null));
    });
  }

  final StorageService _storage;
}
