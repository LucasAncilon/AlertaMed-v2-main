import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../theme/cores.dart';

/// Guarda a gravação feita na tela de cadastro até o medicamento ser salvo.
class MedicationVoiceController {
  String? _pendingPath; // gravação nova, ainda não vinculada a um medicamento
  bool _deleteSaved = false; // usuário apagou a gravação que já existia

  /// Chame depois de salvar o medicamento, com o id dele.
  Future<void> commit(int medicationId) async {
    final voice = VoiceService();
    final pending = _pendingPath;
    if (pending != null) {
      await voice.saveMedicationAudio(medicationId, pending);
    } else if (_deleteSaved) {
      await voice.deleteMedicationAudio(medicationId);
    }
    _pendingPath = null;
    _deleteSaved = false;
  }

  /// Chame no dispose da tela: apaga gravação que não chegou a ser salva.
  Future<void> discard() async {
    final pending = _pendingPath;
    _pendingPath = null;
    if (pending == null) return;
    try {
      final file = File(pending);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

/// Bloco "gravar o nome do remédio com a voz do usuário/cuidador".
class MedicationVoiceRecorder extends StatefulWidget {
  final MedicationVoiceController controller;
  final int? medicationId;

  const MedicationVoiceRecorder({
    super.key,
    required this.controller,
    this.medicationId,
  });

  @override
  State<MedicationVoiceRecorder> createState() =>
      _MedicationVoiceRecorderState();
}

class _MedicationVoiceRecorderState extends State<MedicationVoiceRecorder> {
  String? _savedPath; // gravação já existente deste medicamento
  String? _recordingPath;
  bool _recording = false;
  bool _busy = false;

  MedicationVoiceController get _ctrl => widget.controller;

  String? get _currentAudio =>
      _ctrl._pendingPath ?? (_ctrl._deleteSaved ? null : _savedPath);

  @override
  void initState() {
    super.initState();
    VoiceService().medicationAudioPath(widget.medicationId).then((path) {
      if (mounted) setState(() => _savedPath = path);
    });
  }

  @override
  void dispose() {
    if (_recording) unawaited(VoiceService().cancelRecording());
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    final voice = VoiceService();

    // Fala a instrução ANTES de gravar, para a gravação não pegar a narração.
    await voice
        .say('Diga o nome do remédio.', clip: 'gravar_instrucao')
        .timeout(const Duration(seconds: 6), onTimeout: () {});
    await voice.stop();

    final path = await voice.newTempRecordingPath();
    bool started = false;
    try {
      started = await voice.startRecording(path);
    } catch (_) {
      started = false;
    }
    if (!mounted) {
      if (started) unawaited(voice.cancelRecording());
      return;
    }

    if (!started) {
      setState(() => _busy = false);
      _toast('Não foi possível gravar. Permita o uso do microfone.');
      return;
    }
    setState(() {
      _recording = true;
      _recordingPath = path;
      _busy = false;
    });
  }

  Future<void> _stop() async {
    if (_busy) return;
    setState(() => _busy = true);
    final voice = VoiceService();

    String? path;
    try {
      path = await voice.stopRecording();
    } catch (_) {
      path = null;
    }
    path ??= _recordingPath;
    final ok =
        path != null && File(path).existsSync() && File(path).lengthSync() > 0;
    if (!mounted) {
      // A tela fechou durante a gravação: não deixa arquivo solto.
      if (ok) {
        _ctrl._pendingPath = path;
        await _ctrl.discard();
      }
      return;
    }

    if (ok) {
      // Descarta a gravação temporária anterior, se houver.
      await _ctrl.discard();
      _ctrl._pendingPath = path;
      _ctrl._deleteSaved = false;
      if (!mounted) {
        await _ctrl.discard();
        return;
      }
    }
    setState(() {
      _recording = false;
      _recordingPath = null;
      _busy = false;
    });

    if (ok) {
      unawaited(voice.say(
        'Gravação pronta. Lembre-se de salvar o medicamento.',
        clip: 'gravacao_pronta',
      ));
    } else {
      _toast('A gravação ficou vazia. Tente de novo.');
    }
  }

  void _play() {
    final path = _currentAudio;
    if (path == null) return;
    unawaited(VoiceService().speakSequence([VoicePart('', filePath: path)]));
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar gravação?', style: TextStyle(fontSize: 20)),
        content: const Text(
          'Deseja apagar a gravação do nome do remédio?',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar',
                style: TextStyle(fontSize: 18, color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _ctrl.discard();
    setState(() {
      if (_savedPath != null) _ctrl._deleteSaved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = _currentAudio != null;
    const buttonSize = Size.fromHeight(56);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _recording
                  ? 'Gravando... diga o nome do remédio e toque em Parar.'
                  : hasAudio
                      ? 'Nome do remédio gravado com a sua voz.'
                      : 'Grave o nome do remédio com a sua voz. '
                          'Se não gravar, o app usa a voz do celular.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (_recording)
              ElevatedButton.icon(
                onPressed: _busy ? null : _stop,
                icon: const Icon(Icons.stop, size: 26),
                label: const Text('Parar gravação'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppCores.erro,
                  foregroundColor: Colors.white,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _busy ? null : _start,
                icon: const Icon(Icons.mic, size: 26),
                label: Text(hasAudio ? 'Gravar de novo' : 'Gravar nome'),
              ),
            if (hasAudio && !_recording) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _play,
                icon: const Icon(Icons.play_arrow, size: 26),
                label: const Text('Ouvir gravação',
                    style: TextStyle(fontSize: 18)),
                style: OutlinedButton.styleFrom(minimumSize: buttonSize),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Apagar gravação',
                    style: TextStyle(fontSize: 16, color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
