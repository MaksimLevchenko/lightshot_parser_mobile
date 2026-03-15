import 'package:equatable/equatable.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_progress.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';

enum DownloadUpdateType {
  progress,
  completed,
  cancelled,
  failed,
}

class DownloadUpdate extends Equatable {
  const DownloadUpdate({
    required this.type,
    required this.progress,
    this.message,
    this.item,
  });

  final DownloadUpdateType type;
  final DownloadProgress progress;
  final String? message;
  final GalleryItem? item;

  @override
  List<Object?> get props => [type, progress, message, item];
}
