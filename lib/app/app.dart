import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink, Colors.purple],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ConstrainedBox(
                constraints: BoxConstraints.loose(const Size(200, 200)),
                child: Image.asset('assets/icons/logo.png'),
              ),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Lightshot Parser',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
