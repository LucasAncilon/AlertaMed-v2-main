import 'dart:async';
import 'package:flutter/widgets.dart';
import '../services/voice_service.dart';

/// Narra uma frase (ou sequência) assim que a tela abre.
///
/// Uso: envolva o Scaffold da tela.
///
///   return NarrateOnOpen(
///     parts: const [VoicePart('Tela de pessoas.', clip: 'tela_pessoas')],
///     child: Scaffold(...),
///   );
class NarrateOnOpen extends StatefulWidget {
  final List<VoicePart> parts;
  final Widget child;

  const NarrateOnOpen({super.key, required this.parts, required this.child});

  @override
  State<NarrateOnOpen> createState() => _NarrateOnOpenState();
}

class _NarrateOnOpenState extends State<NarrateOnOpen> {
  final Object _owner = Object();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(VoiceService().speakSequence(widget.parts, owner: _owner));
    });
  }

  @override
  void dispose() {
    // Só corta a fala se ela ainda for desta tela.
    unawaited(VoiceService().stopIfOwnedBy(_owner));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Corta a fala em andamento quando uma nova TELA é aberta, para a narração
/// da tela anterior não continuar por cima da nova.
/// Diálogos (showDialog, seletor de hora etc.) são ignorados de propósito.
///
/// Registrar no MaterialApp:  navigatorObservers: [VoiceNavigatorObserver()]
class VoiceNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) return;
    unawaited(VoiceService().stop());
  }
}
