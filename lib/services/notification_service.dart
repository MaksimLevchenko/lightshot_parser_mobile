import 'dart:async';
import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationAction {
  cancelDownload,
}

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationAction> _actionsController =
      StreamController<NotificationAction>.broadcast();

  Stream<NotificationAction> get actions => _actionsController.stream;

  Future<void> init() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        log('cancelNotification');
        _actionsController.add(NotificationAction.cancelDownload);
      },
    );
  }

  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id: id);
  }

  NotificationDetails progressBarNotificationDetails({
    required int maxValue,
    required int progress,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'channelId',
        'channelName',
        enableVibration: false,
        visibility: NotificationVisibility.public,
        ongoing: true,
        silent: true,
        onlyAlertOnce: true,
        playSound: false,
        importance: Importance.max,
        category: AndroidNotificationCategory.progress,
        maxProgress: maxValue,
        showProgress: true,
        progress: progress,
        priority: Priority.high,
      ),
    );
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'channelId',
        'channelName',
        importance: Importance.max,
      ),
    );
  }

  Future<void> showProgressBarNotification({
    int id = 0,
    required String title,
    required String body,
    required int maxValue,
    required int progress,
  }) async {
    await notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: progressBarNotificationDetails(
        maxValue: maxValue,
        progress: progress,
      ),
      payload: 'cancel-download',
    );
  }

  Future<void> showNotification({
    int id = 1,
    required String title,
    required String body,
  }) async {
    await notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails(),
      payload: 'item x',
    );
  }

  Future<void> dispose() async {
    await _actionsController.close();
  }
}
