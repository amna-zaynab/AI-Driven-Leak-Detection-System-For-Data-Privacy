import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  static const platform = MethodChannel('com.example.privacy_app/files');

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  Future<void> initialize({
    required Function(NotificationResponse) onTap,
  }) async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onTap,
    );
  }

  Future<void> showDownloadNotification({
    required String fileName,
    required String filePath,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'download_channel',
            'Downloads',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            showProgress: false,
            channelShowBadge: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecond,
        'Download Complete',
        '$fileName downloaded successfully',
        notificationDetails,
        payload: filePath,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<void> openFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      try {
        await platform.invokeMethod('openFile', {'filePath': filePath});
      } on PlatformException catch (e) {
        print('Error opening file: ${e.message}');
      } catch (e) {
        print('Error opening file: $e');
      }
    }
  }
}
