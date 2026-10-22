import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/medication.dart';

@pragma('vm:entry-point')
void _bgNotificationHandler(NotificationResponse response) {}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const _channelId = 'alertamed_lembretes_v2';
  static const _channelName = 'Lembretes de Medicamentos';
  static const _channelDesc = 'Lembretes dos horários dos seus medicamentos';

  static final _tapController = StreamController<String>.broadcast();
  static Stream<String> get tapStream => _tapController.stream;

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _bgNotificationHandler,
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    }
  }

  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) _tapController.add(payload);
  }

  Future<String?> getInitialPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.notificationResponse?.payload;
  }

  // payload: medId|name|dosage|voiceReminder|patientName|patientId
  Future<void> schedule(Medication med, {String patientName = ''}) async {
    if (med.id == null || med.notificationTime.isEmpty) return;

    final timeParts = med.notificationTime.split(':');
    if (timeParts.length != 2) return;
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final body = patientName.isNotEmpty
        ? '$patientName — ${med.name} · ${med.dosage}  |  ${med.notificationTime}'
        : '${med.name} — ${med.dosage}  |  ${med.notificationTime}';

    final payload =
        '${med.id}|${med.name}|${med.dosage}|${med.voiceReminder}|$patientName|${med.patientId}';

    if (Platform.isAndroid) {
      final vibrationPattern = Int64List.fromList([0, 600, 300, 600]);
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        playSound: true,
      );
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return;
      await android.zonedSchedule(
        med.id!,
        'Hora do medicamento',
        body,
        scheduled,
        androidDetails,
        scheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } else if (Platform.isIOS) {
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      await _plugin.zonedSchedule(
        med.id!,
        'Hora do medicamento',
        body,
        scheduled,
        const NotificationDetails(iOS: iosDetails),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    }
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();
}
