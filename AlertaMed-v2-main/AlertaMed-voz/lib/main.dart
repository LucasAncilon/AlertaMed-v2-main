import 'dart:async';
import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'services/notification_service.dart';
import 'services/tts_service.dart';
import 'services/voice_service.dart';
import 'widgets/narrate_on_open.dart';
import 'theme/tema.dart';
import 'screens/patient_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/session_gate.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(const AlertaMedApp());
}

class AlertaMedApp extends StatefulWidget {
  const AlertaMedApp({super.key});

  @override
  State<AlertaMedApp> createState() => _AlertaMedAppState();
}

class _AlertaMedAppState extends State<AlertaMedApp>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _notifSub;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifSub = NotificationService.tapStream.listen(_handlePayload);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkInitialNotification(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifSub?.cancel();
    super.dispose();
  }

  // Registra quando o app vai para background.
  // Ao voltar, verifica se algum medicamento foi notificado enquanto
  // o app estava em segundo plano e fala o lembrete.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _backgroundedAt != null) {
      final bg = _backgroundedAt!;
      _backgroundedAt = null;
      _speakIfNotificationJustFired(bg);
    }
  }

  // Verifica se algum medicamento tinha notificação agendada nos
  // últimos 5 minutos. Caso sim, fala o lembrete via TTS.
  Future<void> _speakIfNotificationJustFired(DateTime backgroundedAt) async {
    if (!mounted) return;
    final now = DateTime.now();
    final fiveMinAgo = now.subtract(const Duration(minutes: 5));

    final patients = await DatabaseHelper().getPatients();
    for (final patient in patients) {
      if (patient.id == null) continue;
      final meds = await DatabaseHelper().getMedicationsByPatient(patient.id!);
      for (final med in meds) {
        if (med.notificationTime.isEmpty) continue;
        final parts = med.notificationTime.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]);
        final min = int.tryParse(parts[1]);
        if (hour == null || min == null) continue;

        final notifTime = DateTime(now.year, now.month, now.day, hour, min);

        // Notificação disparou após o app ir para background E nos
        // últimos 5 minutos em relação ao momento de retorno.
        if (notifTime.isAfter(backgroundedAt) &&
            notifTime.isAfter(fiveMinAgo) &&
            notifTime.isBefore(now.add(const Duration(minutes: 1)))) {
          if (!mounted) return;
          VoiceService().speakReminder(med, patientName: patient.name);
          return;
        }
      }
    }
  }

  Future<void> _checkInitialNotification() async {
    final payload = await NotificationService().getInitialPayload();
    if (payload != null) await _handlePayload(payload);
  }

  // payload: medId|name|dosage|voiceReminder|patientName|patientId
  // Usado quando o callback de tap chega ao Dart (funciona no Android
  // e em configurações iOS sem FlutterImplicitEngineDelegate).
  Future<void> _handlePayload(String payload) async {
    final parts = payload.split('|');
    if (parts.length < 2) return;

    final medName = parts[1];
    final dosage = parts.length >= 3 ? parts[2] : '';
    final patientName = parts.length >= 5 ? parts[4] : '';
    final patientId = parts.length >= 6 ? int.tryParse(parts[5]) ?? 1 : 1;

    final patient = await DatabaseHelper().getPatientById(patientId);
    if (patient == null) return;

    final nav = _navigatorKey.currentState;
    if (nav == null) return;

    // Proteção temporária: os dados SQLite ainda não possuem
    // isolamento por usuário. Não abrir telas de pacientes
    // por notificações até integrar a autorização ao backend.
    if (nav.mounted) {
      return;
    }

    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PatientListScreen()),
      (route) => false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nav.push(MaterialPageRoute(builder: (_) => HomeScreen(patient: patient)));
    });

    TtsService().speakReminder(medName, dosage, patientName: patientName);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlertaMed',
      debugShowCheckedModeBanner: false,
      theme: buildTema(),
      navigatorKey: _navigatorKey,
      navigatorObservers: [VoiceNavigatorObserver()],
      home: const SessionGate(),
    );
  }
}
