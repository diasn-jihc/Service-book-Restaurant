import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/worker.dart';
import '../services/storage_service.dart';

abstract class AuthEvent {}

class UserRegistered extends AuthEvent {
  final Worker user;
  UserRegistered(this.user);
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
