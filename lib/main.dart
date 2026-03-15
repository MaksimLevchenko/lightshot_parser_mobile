import 'package:flutter/widgets.dart';
import 'package:lightshot_parser_mobile/app/app.dart';
import 'package:lightshot_parser_mobile/features/download/data/datasources/lightshot_remote_data_source.dart';
import 'package:lightshot_parser_mobile/features/download/data/repositories/download_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/datasources/gallery_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/data/repositories/photo_actions_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final SettingsRepository _settingsRepository;
  late final GalleryRepository _galleryRepository;
  late final DownloadRepository _downloadRepository;
  late final PhotoActionsRepository _photoActionsRepository;
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _settingsRepository = SettingsRepository(SettingsLocalDataSource());
    _galleryRepository = GalleryRepository(
      settingsRepository: _settingsRepository,
      localDataSource: GalleryLocalDataSource(),
    );
    _downloadRepository = DownloadRepository(
      remoteDataSource: LightshotRemoteDataSource(),
      galleryRepository: _galleryRepository,
    );
    _photoActionsRepository = PhotoActionsRepository(_galleryRepository);
    _notificationService = NotificationService();
  }

  @override
  Future<void> dispose() async {
    await _galleryRepository.dispose();
    await _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return App(
      settingsRepository: _settingsRepository,
      galleryRepository: _galleryRepository,
      downloadRepository: _downloadRepository,
      photoActionsRepository: _photoActionsRepository,
      notificationService: _notificationService,
    );
  }
}
