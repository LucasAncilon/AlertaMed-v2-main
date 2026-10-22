import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/voice_phrases.dart';
import '../services/voice_service.dart';
import '../theme/cores.dart';
import '../widgets/narrate_on_open.dart';

/// Voz personalizável: o usuário grava, uma a uma, as frases do aplicativo.
class CustomVoiceScreen extends StatefulWidget {
  const CustomVoiceScreen({super.key});

  @override
  State<CustomVoiceScreen> createState() => _CustomVoiceScreenState();
}

class _CustomVoiceScreenState extends State<CustomVoiceScreen> {
  final _voice = VoiceService();

  Set<String> _recorded = {};
  String? _recordingKey;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadRecorded();
  }

  @override
  void dispose() {
    if (_recordingKey != null) unawaited(_voice.cancelRecording());
    super.dispose();
  }

  Future<void> _loadRecorded() async {
    final keys = await _voice.recordedCustomKeys();
    if (mounted) setState(() => _recorded = keys);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _start(VoicePhrase phrase) async {
    if (_busy || _recordingKey != null) return;
    setState(() => _busy = true);

    // O app lê a frase ANTES de gravar, para a gravação não pegar a narração.
    await _voice
        .say('Diga: ${phrase.text}')
        .timeout(const Duration(seconds: 30), onTimeout: () {});
    await _voice.stop();

    final path = await _voice.newCustomTempPath(phrase.key);
    bool started = false;
    try {
      started = await _voice.startRecording(path);
    } catch (_) {
      started = false;
    }
    if (!mounted) {
      if (started) unawaited(_voice.cancelRecording());
      return;
    }
    if (!started) {
      setState(() => _busy = false);
      _toast('Não foi possível gravar. Permita o uso do microfone.');
      return;
    }
    setState(() {
      _recordingKey = phrase.key;
      _busy = false;
    });
  }

  Future<void> _stop(VoicePhrase phrase) async {
    if (_busy) return;
    setState(() => _busy = true);

    String? path;
    try {
      path = await _voice.stopRecording();
    } catch (_) {
      path = null;
    }
    bool ok = false;
    if (path != null && File(path).existsSync() && File(path).lengthSync() > 0) {
      await _voice.saveCustomPhrase(phrase.key, path);
      ok = true;
    }
    if (!mounted) return;

    final keys = await _voice.recordedCustomKeys();
    if (!mounted) return;
    setState(() {
      _recorded = keys;
      _recordingKey = null;
      _busy = false;
    });

    if (ok) {
      unawaited(_voice.say('Gravação salva.'));
    } else {
      _toast('A gravação ficou vazia. Tente de novo.');
    }
  }

  Future<void> _play(VoicePhrase phrase) async {
    final path = await _voice.customPhrasePath(phrase.key);
    if (path == null) return;
    unawaited(_voice.playFile(path));
  }

  Future<void> _delete(VoicePhrase phrase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar gravação?', style: TextStyle(fontSize: 20)),
        content: const Text(
          'Deseja apagar a gravação desta frase?',
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
    if (confirmed != true) return;
    await _voice.deleteCustomPhrase(phrase.key);
    await _loadRecorded();
  }

  @override
  Widget build(BuildContext context) {
    return NarrateOnOpen(
      parts: const [
        VoicePart(
          'Minha voz. Escolha uma frase e grave com a sua voz.',
          clip: 'tela_minha_voz',
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Minha voz')),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Toque em Gravar. O aplicativo lê a frase e, depois, '
                      'você repete com a sua voz.',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_recorded.length} de ${kVoicePhrases.length} '
                      'frases gravadas',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppCores.primaria,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              for (final phrase in kVoicePhrases) _buildPhrase(phrase),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhrase(VoicePhrase phrase) {
    final hasAudio = _recorded.contains(phrase.key);
    final isRecording = _recordingKey == phrase.key;
    final otherRecording = _recordingKey != null && !isRecording;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    phrase.where,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppCores.textoSecundario,
                    ),
                  ),
                ),
                Icon(
                  hasAudio ? Icons.check_circle : Icons.circle_outlined,
                  color: hasAudio ? AppCores.sucesso : Colors.grey,
                  semanticLabel: hasAudio ? 'Gravada' : 'Não gravada',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(phrase.text, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            if (isRecording)
              ElevatedButton.icon(
                onPressed: _busy ? null : () => _stop(phrase),
                icon: const Icon(Icons.stop, size: 26),
                label: const Text('Parar gravação'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppCores.erro,
                  foregroundColor: Colors.white,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed:
                    (_busy || otherRecording) ? null : () => _start(phrase),
                icon: const Icon(Icons.mic, size: 26),
                label: Text(hasAudio ? 'Gravar de novo' : 'Gravar'),
              ),
            if (hasAudio && _recordingKey == null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _play(phrase),
                      icon: const Icon(Icons.play_arrow, size: 26),
                      label: const Text('Ouvir',
                          style: TextStyle(fontSize: 18)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _busy ? null : () => _delete(phrase),
                      icon:
                          const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Apagar',
                          style: TextStyle(fontSize: 16, color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
