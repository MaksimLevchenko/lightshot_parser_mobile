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

  final settingsRepository = SettingsRepository(SettingsLocalDataSource());
  final galleryRepository = GalleryRepository(
    settingsRepository: settingsRepository,
    localDataSource: GalleryLocalDataSource(),
  );
  final downloadRepository = DownloadRepository(
    remoteDataSource: LightshotRemoteDataSource(),
    galleryRepository: galleryRepository,
  );
  final photoActionsRepository = PhotoActionsRepository(galleryRepository);
  final notificationService = NotificationService();

  runApp(
    App(
      settingsRepository: settingsRepository,
      galleryRepository: galleryRepository,
      downloadRepository: downloadRepository,
      photoActionsRepository: photoActionsRepository,
      notificationService: notificationService,
    ),
  );
}
