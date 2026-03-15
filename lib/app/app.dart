import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lightshot_parser_mobile/core/theme/app_scroll_behavior.dart';
import 'package:lightshot_parser_mobile/core/theme/app_theme.dart';
import 'package:lightshot_parser_mobile/core/widgets/status_view.dart';
import 'package:lightshot_parser_mobile/features/bootstrap/presentation/cubit/bootstrap_cubit.dart';
import 'package:lightshot_parser_mobile/features/bootstrap/presentation/cubit/bootstrap_state.dart';
import 'package:lightshot_parser_mobile/features/download/data/repositories/download_repository.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_bloc.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/pages/home_page.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_cubit.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/data/repositories/photo_actions_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';
import 'package:lightshot_parser_mobile/services/notification_service.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    required this.settingsRepository,
    required this.galleryRepository,
    required this.downloadRepository,
    required this.photoActionsRepository,
    required this.notificationService,
  });

  final SettingsRepository settingsRepository;
  final GalleryRepository galleryRepository;
  final DownloadRepository downloadRepository;
  final PhotoActionsRepository photoActionsRepository;
  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: settingsRepository),
        RepositoryProvider.value(value: galleryRepository),
        RepositoryProvider.value(value: downloadRepository),
        RepositoryProvider.value(value: photoActionsRepository),
        RepositoryProvider.value(value: notificationService),
      ],
      child: BlocProvider(
        create: (_) => BootstrapCubit(
          settingsRepository: settingsRepository,
          galleryRepository: galleryRepository,
          notificationService: notificationService,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            S.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          theme: buildAppTheme(),
          scrollBehavior: const AppScrollBehavior(),
          home: const AppView(),
        ),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BootstrapCubit, BootstrapState>(
      builder: (context, state) {
        switch (state.status) {
          case BootstrapStatus.initial:
          case BootstrapStatus.loading:
            return const SplashPage();
          case BootstrapStatus.failure:
            return Scaffold(
              body: StatusView(
                message: state.errorMessage ?? 'Bootstrap failed',
                icon: Icons.error_outline,
              ),
            );
          case BootstrapStatus.ready:
            return MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => GalleryCubit(
                    context.read<GalleryRepository>(),
                  ),
                ),
                BlocProvider(
                  create: (_) => DownloadBloc(
                    downloadRepository: context.read<DownloadRepository>(),
                    settingsRepository: context.read<SettingsRepository>(),
                    notificationService: context.read<NotificationService>(),
                  ),
                ),
              ],
              child: const HomePage(),
            );
        }
      },
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8EEE5),
              Color(0xFFECCEC0),
              Color(0xFFDFAEA0),
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              left: -120,
              top: -80,
              child: _SplashOrb(
                size: 260,
                color: Color(0x66FFFFFF),
              ),
            ),
            const Positioned(
              right: -70,
              bottom: -90,
              child: _SplashOrb(
                size: 240,
                color: Color(0x44FFFFFF),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    color: AppColors.panel.withValues(alpha: 0.92),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 32,
                                  offset: Offset(0, 18),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Image.asset('assets/icons/logo.png'),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Lightshot Parser',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontSize: 30,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const LinearProgressIndicator(minHeight: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashOrb extends StatelessWidget {
  const _SplashOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
