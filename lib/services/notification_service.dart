import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
  }

  Future<void> initNotification(onRecieveNotificationResponce) async {
    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: null);
    await notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: ((details) {
      log('cancelNotification');
      // onRecieveNotificationResponce();
    }));
  }

  // AndroidNotificationAction actionCancel(BuildContext context) {
  //   return AndroidNotificationAction(
  //     cancelNotification: true,
  //     'channelId',
  //     S.of(context).cancel,
  //   );
  // }

  progressBarNotificationDetails(
      {required int maxValue,
      required int progress,
      required BuildContext context}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'channelId',
        'channelName',
        // actions: [
        //   actionCancel(context),
        // ],
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

  notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'channelId',
        'channelName',
        importance: Importance.max,
      ),
    );
  }

  Future showProgressBarNotification(
      {int id = 0,
      required String title,
      required String body,
      required int maxValue,
      required int progress,
      required BuildContext context}) async {
    return notificationsPlugin.show(
        id,
        title,
        body,
        await progressBarNotificationDetails(
            maxValue: maxValue, progress: progress, context: context),
        payload: 'item x');
  }

  Future showNotification(
      {int id = 1, required String title, required String body}) async {
    return notificationsPlugin
        .show(id, title, body, await notificationDetails(), payload: 'item x');
  }
}
