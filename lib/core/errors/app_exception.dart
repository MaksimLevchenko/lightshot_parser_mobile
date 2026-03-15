class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CouldNotConnectException extends AppException {
  const CouldNotConnectException([super.message = 'Could not connect']);
}

class CancelledDownloadException extends AppException {
  const CancelledDownloadException([super.message = 'Download cancelled']);
}

class NoPhotoException extends AppException {
  const NoPhotoException([super.message = 'No photo found']);
}

class DownloadTransportException extends AppException {
  const DownloadTransportException(
      [super.message = 'Download transport failed']);
}

class StorageException extends AppException {
  const StorageException([super.message = 'Storage operation failed']);
}
