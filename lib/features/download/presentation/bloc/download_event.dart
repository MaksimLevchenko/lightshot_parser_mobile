import 'package:equatable/equatable.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_update.dart';

sealed class DownloadEvent extends Equatable {
  const DownloadEvent();

  @override
  List<Object?> get props => [];
}

class DownloadRequested extends DownloadEvent {
  const DownloadRequested();
}

class DownloadCancelled extends DownloadEvent {
  const DownloadCancelled();
}

class DownloadFeedbackCleared extends DownloadEvent {
  const DownloadFeedbackCleared();
}

class DownloadUpdateReceived extends DownloadEvent {
  const DownloadUpdateReceived(this.update);

  final DownloadUpdate update;

  @override
  List<Object?> get props => [update];
}
