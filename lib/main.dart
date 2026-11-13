import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'blocs/auth_bloc.dart';
import 'blocs/city_cubit.dart';
import 'blocs/checklist_bloc.dart';
import 'blocs/data_cubit.dart';
import 'blocs/theme_bloc.dart';
import 'constants.dart';
import 'data/app_repository.dart';
import 'models/user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/guest/guest_shell.dart';
import 'screens/staff/staff_shell.dart';
import 'services/api_client.dart';
import 'services/photo_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru'); // русские даты
  final prefs = await SharedPreferences.getInstance();
  final store = StorageService(prefs);
  final repo = AppRepository(store);
  await repo.load();

  runApp(StolikApp(store: store, repo: repo));
}

class StolikApp extends StatelessWidget {
  const StolikApp({super.key, required this.store, required this.repo});

  final StorageService store;
  final AppRepository repo;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>(create: (_) => ApiClient()),
        RepositoryProvider<PhotoService>(create: (_) => PhotoService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => DataCubit(repo)),
          BlocProvider(create: (_) => AuthBloc(repo)),
          BlocProvider(create: (_) => CityCubit(store)),
          BlocProvider(create: (_) => ChecklistBloc(store)),
          BlocProvider(create: (_) => ThemeBloc(store)),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final accent = accentOptions[themeState.accentIndex].color;
            return MaterialApp(
              title: appName,
              debugShowCheckedModeBanner: false,
              theme: buildTheme(accent),
              locale: const Locale('ru'),
              supportedLocales: const [Locale('ru')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // Не вошли — экран входа. Гость и сотрудник видят разные кабинеты.
              home: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, auth) {
                  final user = auth.user;
                  if (user == null) return const LoginScreen();
                  if (user.role == UserRole.guest) {
                    return GuestShell(key: ValueKey(user.id));
                  }
                  return StaffShell(key: ValueKey(user.id));
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
