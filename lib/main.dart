import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'blocs/auth_bloc.dart';
import 'blocs/checklist_bloc.dart';
import 'blocs/guests_cubit.dart';
import 'blocs/journal_bloc.dart';
import 'blocs/theme_bloc.dart';
import 'blocs/workers_bloc.dart';
import 'screens/home_screen.dart';
import 'screens/registration_screen.dart';
import 'services/api_client.dart';
import 'services/file_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  final prefs = await SharedPreferences.getInstance();

  runApp(ServiceBookApp(
    storage: StorageService(prefs),
    api: ApiClient(),
  ));
}

class ServiceBookApp extends StatelessWidget {
  const ServiceBookApp({super.key, required this.storage, required this.api});

  final StorageService storage;
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>.value(value: api),
        RepositoryProvider<FileService>(create: (_) => FileService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthBloc(storage)),
          BlocProvider(create: (_) => WorkersBloc(storage)),
          BlocProvider(create: (_) => JournalBloc(storage, api)),
          BlocProvider(create: (_) => ChecklistBloc(storage)),
          BlocProvider(create: (_) => ThemeBloc(storage)),
          BlocProvider(create: (_) => GuestsCubit(storage)),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final accent = accentOptions[themeState.accentIndex].color;
            return MaterialApp(
              title: 'РЎРµСЂРІРёСЃРЅР°СЏ РєРЅРёР¶РєР°',
              debugShowCheckedModeBanner: false,
              theme: buildTheme(accent),
              locale: const Locale('ru'),
              supportedLocales: const [Locale('ru')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, auth) => auth.isLoggedIn
                    ? const HomeScreen()
                    : const RegistrationScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
