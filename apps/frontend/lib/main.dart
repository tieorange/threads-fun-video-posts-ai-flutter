import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/logging/log_entry.dart';
import 'core/logging/logger.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/utils/router.dart';
import 'i18n/strings.g.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class _AppBlocObserver extends BlocObserver {
  const _AppBlocObserver(this._log);
  final AppLogger _log;

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    _log.debug(
      'cubit_state_change',
      '${bloc.runtimeType}: ${change.currentState.runtimeType} → ${change.nextState.runtimeType}',
      layer: AppLayer.presentation,
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _log.error(
      'cubit_error',
      '${bloc.runtimeType}: $error',
      layer: AppLayer.presentation,
      stack: stackTrace.toString(),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    BrowserContextMenu.enableContextMenu();
  }

  // Initialize Slang and set Ukrainian as default
  LocaleSettings.setLocale(AppLocale.uk);

  setupDependencies();

  final log = sl<AppLogger>();

  // Global Flutter framework error hook
  FlutterError.onError = (details) {
    log.error(
      'flutter_error',
      details.exceptionAsString(),
      layer: AppLayer.core,
      feature: 'core',
      stack: details.stack?.toString(),
      data: {'library': details.library ?? 'unknown'},
    );
    FlutterError.presentError(details);
  };

  // Global platform error hook (async errors not caught by Flutter framework)
  PlatformDispatcher.instance.onError = (error, stack) {
    log.error(
      'platform_error',
      error.toString(),
      layer: AppLayer.core,
      feature: 'core',
      stack: stack.toString(),
    );
    return false;
  };

  // BlocObserver for cubit transitions
  Bloc.observer = _AppBlocObserver(log);

  log.info('app_start', 'App starting', layer: AppLayer.core, feature: 'core');

  initCubits();
  runApp(
    MultiBlocProvider(
      providers: [BlocProvider(create: (_) => sl<ThemeCubit>())],
      child: TranslationProvider(child: const FunnyThreadsApp()),
    ),
  );
}

class FunnyThreadsApp extends StatelessWidget {
  const FunnyThreadsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp.router(
          title: 'Funny Threads AI',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
          locale: TranslationProvider.of(context).flutterLocale, // use slang locale
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        );
      },
    );
  }
}
