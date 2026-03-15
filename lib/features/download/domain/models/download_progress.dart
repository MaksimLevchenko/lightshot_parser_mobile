import 'package:equatable/equatable.dart';

class DownloadProgress extends Equatable {
  const DownloadProgress({
    required this.downloadedCount,
    required this.totalCount,
  });

  const DownloadProgress.initial()
      : downloadedCount = 0,
        totalCount = 0;

  final int downloadedCount;
  final int totalCount;

  double get fraction {
    if (totalCount == 0) {
      return 0;
    }
    return downloadedCount / totalCount;
  }

  @override
  List<Object?> get props => [downloadedCount, totalCount];
}
