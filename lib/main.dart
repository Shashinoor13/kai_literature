import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'package:literature/core/theme/app_theme.dart';
import 'package:literature/core/routing/app_router.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/messaging/bloc/messaging_bloc.dart';
import 'package:literature/features/theme/bloc/theme_bloc.dart';
import 'package:literature/features/theme/bloc/theme_event.dart';
import 'package:literature/features/theme/bloc/theme_state.dart';
import 'package:literature/repositories/auth_repository.dart';
import 'package:literature/repositories/messaging_repository.dart';
import 'package:literature/repositories/post_repository.dart';
import 'package:literature/repositories/theme_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set preferred orientations (portrait only for MVP)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const LiteratureApp());
}

class LiteratureApp extends StatefulWidget {
  const LiteratureApp({super.key});

  @override
  State<LiteratureApp> createState() => _LiteratureAppState();
}

class _LiteratureAppState extends State<LiteratureApp> {
  // Create repositories once
  late final AuthRepository _authRepository;
  late final MessagingRepository _messagingRepository;
  late final PostRepository _postRepository;
  late final ThemeRepository _themeRepository;

  // Create BLoCs once
  late final AuthBloc _authBloc;
  late final MessagingBloc _messagingBloc;
  late final ThemeBloc _themeBloc;

  // Create router once
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();

    // Initialize repositories
    _authRepository = AuthRepository();
    _messagingRepository = MessagingRepository();
    _postRepository = PostRepository();
    _themeRepository = ThemeRepository();

    // Initialize BLoCs (auth check happens in AuthBloc constructor)
    _authBloc = AuthBloc(authRepository: _authRepository);
    _messagingBloc = MessagingBloc(messagingRepository: _messagingRepository);
    _themeBloc = ThemeBloc(themeRepository: _themeRepository)
      ..add(const LoadTheme());

    // Initialize router
    _appRouter = AppRouter(authBloc: _authBloc);
  }

  @override
  void dispose() {
    // Clean up BLoCs
    _authBloc.close();
    _messagingBloc.close();
    _themeBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<MessagingRepository>.value(
          value: _messagingRepository,
        ),
        RepositoryProvider<PostRepository>.value(value: _postRepository),
        RepositoryProvider<ThemeRepository>.value(value: _themeRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: _authBloc),
          BlocProvider<MessagingBloc>.value(value: _messagingBloc),
          BlocProvider<ThemeBloc>.value(value: _themeBloc),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp.router(
              title: 'Literature',
              debugShowCheckedModeBanner: false,

              // Apply theme from ThemeBloc
              theme: themeState is ThemeLoaded
                  ? themeState.themeData
                  : AppTheme.darkTheme,

              // Router configuration
              routerConfig: _appRouter.router,
            );
          },
        ),
      ),
    );
  }
}
