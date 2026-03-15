import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';

enum NotificationAction {
  cancelDownload,
}

class NotificationService {
  NotificationService();

  static const String _defaultNotificationIcon =
      'resource://drawable/ic_notification_download';
  static const String _progressChannelKey = 'download_progress';
  static const String _statusChannelKey = 'download_status';
  static const String _cancelDownloadPayloadKey = 'action';
  static const String _cancelDownloadPayloadValue = 'cancel-download';

  static NotificationService? _activeInstance;

  final StreamController<NotificationAction> _actionsController =
      StreamController<NotificationAction>.broadcast();

  Stream<NotificationAction> get actions => _actionsController.stream;

  Future<void> init() async {
    _activeInstance = this;
    await AwesomeNotifications().initialize(
      _defaultNotificationIcon,
      [
        NotificationChannel(
          channelKey: _progressChannelKey,
          channelName: 'Download progress',
          channelDescription: 'Shows the current download progress',
          importance: NotificationImportance.Max,
          playSound: false,
          enableVibration: false,
          defaultPrivacy: NotificationPrivacy.Public,
          locked: true,
          onlyAlertOnce: true,
          channelShowBadge: false,
        ),
        NotificationChannel(
          channelKey: _statusChannelKey,
          channelName: 'Download status',
          channelDescription: 'Shows the final download status',
          importance: NotificationImportance.Max,
        ),
      ],
      debug: kDebugMode,
    );

    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
    );

    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  Future<void> showProgressBarNotification({
    int id = 0,
    required String title,
    required String body,
    required int maxValue,
    required int progress,
  }) async {
    final progressPercent = maxValue == 0 ? 0.0 : (progress / maxValue) * 100.0;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: _progressChannelKey,
        icon: _defaultNotificationIcon,
        title: title,
        body: body,
        category: NotificationCategory.Progress,
        notificationLayout: NotificationLayout.ProgressBar,
        progress: progressPercent.clamp(0.0, 100.0),
        locked: true,
        autoDismissible: false,
        payload: const {
          _cancelDownloadPayloadKey: _cancelDownloadPayloadValue,
        },
      ),
    );
  }

  Future<void> showNotification({
    int id = 1,
    required String title,
    required String body,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: _statusChannelKey,
        icon: _defaultNotificationIcon,
        title: title,
        body: body,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    final service = _activeInstance;
    if (service == null || service._actionsController.isClosed) {
      return;
    }
    final action = receivedAction.payload?[_cancelDownloadPayloadKey];
    if (action == _cancelDownloadPayloadValue) {
      service._actionsController.add(NotificationAction.cancelDownload);
    }
  }

  Future<void> dispose() async {
    if (identical(_activeInstance, this)) {
      _activeInstance = null;
    }
    await _actionsController.close();
  }
}
