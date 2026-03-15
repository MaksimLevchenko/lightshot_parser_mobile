import 'package:equatable/equatable.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_progress.dart';

enum DownloadStatus {
  idle,
  inProgress,
  cancelled,
  completed,
  failure,
}

class DownloadState extends Equatable {
  const DownloadState({
    required this.status,
    required this.progress,
    this.failureCode,
    this.errorDetails,
  });

  const DownloadState.initial()
      : status = DownloadStatus.idle,
        progress = const DownloadProgress.initial(),
        failureCode = null,
        errorDetails = null;

  final DownloadStatus status;
  final DownloadProgress progress;
  final String? failureCode;
  final String? errorDetails;

  bool get isDownloading => status == DownloadStatus.inProgress;

  DownloadState copyWith({
    DownloadStatus? status,
    DownloadProgress? progress,
    String? failureCode,
    String? errorDetails,
    bool clearFailure = false,
  }) {
    return DownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      failureCode: clearFailure ? null : failureCode ?? this.failureCode,
      errorDetails: clearFailure ? null : errorDetails ?? this.errorDetails,
    );
  }

  @override
  List<Object?> get props => [status, progress, failureCode, errorDetails];
}
