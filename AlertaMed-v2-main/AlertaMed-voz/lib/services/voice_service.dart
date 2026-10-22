import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart'
    show AssetSource, AudioPlayer, DeviceFileSource, Source;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' show AudioRecorder, RecordConfig;

import '../models/medication.dart';
import 'tts_service.dart';

/// Qual voz o aplicativo usa para as frases fixas.
enum VoiceMode {
  /// Voz sintética do celular (comportamento original do app).
  padrao,

  /// Gravações da equipe de desenvolvimento (assets/audio).
  desenvolvedores,

  /// Gravações feitas pelo próprio usuário (tela "Minha voz").
  personalizada,
}

/// Um "pedaço" de fala.
///
/// - [filePath]: gravação do nome de um remédio (usada em qualquer modo).
/// - [clip]: chave da frase fixa; o áudio usado depende do [VoiceMode].
/// - [text]: voz sintética, usada quando não há áudio.
class VoicePart {
  final String text;
  final String? clip;
  final String? filePath;

  const VoicePart(this.text, {this.clip, this.filePath});
}

/// Narração do app. Respeita o botão de som da tela de medicamentos
/// (`TtsService().soundEnabled`): se estiver silenciado, não fala nada.
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  static const _assetPrefix = 'assets/audio/';
  static const _audioExtensions = {'mp3', 'm4a', 'wav', 'ogg', 'aac'};

  // Cada nova fala incrementa [_gen]; falas antigas percebem e se encerram.
  int _gen = 0;
  Object? _owner;

  AudioPlayer? _player;
  Completer<void>? _playbackDone;

  // chave da frase -> caminho para o AssetSource (voz dos desenvolvedores)
  final Map<String, String> _clips = {};
  bool _clipsLoaded = false;

  VoiceMode _mode = VoiceMode.padrao;
  bool _settingsLoaded = false;

  AudioRecorder? _rec;
  AudioRecorder get _recorder => _rec ??= AudioRecorder();

  Directory? _baseDir;
  Directory? _medDir;
  Directory? _customDir;

  // ---------------------------------------------------------------------------
  // Configuração: qual voz usar
  // ---------------------------------------------------------------------------

  VoiceMode get mode => _mode;

  /// Lê a voz escolhida (feito uma vez só).
  Future<void> loadSettings() async {
    if (_settingsLoaded) return;
    try {
      final file = File('${(await _root()).path}/voice_mode.txt');
      if (await file.exists()) {
        final value = (await file.readAsString()).trim();
        _mode = VoiceMode.values.firstWhere(
          (m) => m.name == value,
          orElse: () => VoiceMode.padrao,
        );
      }
    } catch (_) {}
    _settingsLoaded = true;
  }

  Future<void> setMode(VoiceMode mode) async {
    _mode = mode;
    _settingsLoaded = true;
    try {
      final file = File('${(await _root()).path}/voice_mode.txt');
      await file.writeAsString(mode.name);
    } catch (_) {}
  }

  /// Quantas frases gravadas pela equipe existem em assets/audio.
  Future<int> developerClipCount() async {
    await _loadClips();
    return _clips.length;
  }

  // ---------------------------------------------------------------------------
  // Falar
  // ---------------------------------------------------------------------------

  /// Fala uma frase. O Future termina quando a fala acaba (ou é interrompida).
  Future<void> say(String text, {String? clip}) =>
      speakSequence([VoicePart(text, clip: clip)]);

  /// Fala vários pedaços em sequência, interrompendo qualquer fala anterior.
  /// [owner] permite que quem iniciou a fala a interrompa depois
  /// (veja [stopIfOwnedBy]).
  Future<void> speakSequence(List<VoicePart> parts, {Object? owner}) async {
    if (!TtsService().soundEnabled) return;

    final gen = ++_gen;
    _owner = owner;
    await _stopPlayback();
    await TtsService().stop();
    await loadSettings();
    await _loadClips();

    for (final part in parts) {
      if (gen != _gen) return;
      await _speakPart(part, gen);
    }
  }

  /// Toca um arquivo de áudio direto (pré-escuta de gravações), em qualquer
  /// modo de voz.
  Future<void> playFile(String path) async {
    final gen = ++_gen;
    _owner = null;
    await _stopPlayback();
    await TtsService().stop();
    if (!File(path).existsSync()) return;
    await _playSource(DeviceFileSource(path), gen);
  }

  /// Fala o medicamento: nome (gravação do usuário, se houver) e dosagem.
  Future<void> speakMedication(Medication med) async {
    final recorded = await medicationAudioPath(med.id);
    if (recorded != null) {
      await speakSequence([
        VoicePart(med.name, filePath: recorded),
        VoicePart(med.dosage),
      ]);
    } else {
      await speakSequence([VoicePart('${med.name}, ${med.dosage}.')]);
    }
  }

  /// Lembrete de hora de tomar o remédio.
  Future<void> speakReminder(Medication med, {String patientName = ''}) async {
    if (!TtsService().soundEnabled) return;
    await loadSettings();
    await _loadClips();
    final recorded = await medicationAudioPath(med.id);
    final hasIntro = await _hasPhraseAudio('hora_do_medicamento');

    if (recorded == null && !hasIntro) {
      // Nada gravado: mantém a mesma frase que o app já falava antes.
      final prefix = patientName.isNotEmpty ? '$patientName, ' : '';
      await speakSequence([
        VoicePart('${prefix}hora do medicamento ${med.name}, ${med.dosage}.'),
      ]);
      return;
    }

    await speakSequence([
      if (patientName.isNotEmpty) VoicePart('$patientName.'),
      const VoicePart('Hora do medicamento.', clip: 'hora_do_medicamento'),
      VoicePart(med.name, filePath: recorded),
      VoicePart(med.dosage),
    ]);
  }

  /// Interrompe qualquer fala em andamento.
  Future<void> stop() async {
    _gen++;
    _owner = null;
    await _stopPlayback();
    await TtsService().stop();
  }

  /// Interrompe a fala somente se ela foi iniciada por [owner].
  Future<void> stopIfOwnedBy(Object owner) async {
    if (identical(_owner, owner)) await stop();
  }

  /// Existe áudio gravado para esta frase no modo de voz atual?
  Future<bool> _hasPhraseAudio(String key) async {
    switch (_mode) {
      case VoiceMode.padrao:
        return false;
      case VoiceMode.desenvolvedores:
        return _clips.containsKey(key);
      case VoiceMode.personalizada:
        return (await customPhrasePath(key)) != null;
    }
  }

  Future<void> _speakPart(VoicePart part, int gen) async {
    // 1) Nome de remédio gravado pelo usuário (vale em qualquer modo).
    final file = part.filePath;
    if (file != null && File(file).existsSync()) {
      if (await _playSource(DeviceFileSource(file), gen)) return;
    }

    // 2) Áudio da frase fixa, conforme a voz escolhida.
    final key = part.clip;
    if (key != null) {
      if (_mode == VoiceMode.personalizada) {
        final custom = await customPhrasePath(key);
        if (custom != null && await _playSource(DeviceFileSource(custom), gen)) {
          return;
        }
      } else if (_mode == VoiceMode.desenvolvedores) {
        final asset = _clips[key];
        if (asset != null && await _playSource(AssetSource(asset), gen)) {
          return;
        }
      }
    }

    // 3) Voz sintética.
    if (gen != _gen) return;
    await TtsService()
        .speakText(part.text, wait: true)
        .timeout(const Duration(seconds: 45), onTimeout: () {});
  }

  /// Toca um áudio até o fim. Retorna false se não conseguiu tocar.
  Future<bool> _playSource(Source source, int gen) async {
    if (gen != _gen) return true;

    final player = AudioPlayer();
    final done = Completer<void>();
    _player = player;
    _playbackDone = done;

    final sub = player.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });

    try {
      await player.play(source);
      await done.future.timeout(const Duration(seconds: 90));
      return true;
    } catch (_) {
      return false;
    } finally {
      await sub.cancel();
      if (identical(_player, player)) {
        _player = null;
        _playbackDone = null;
      }
      try {
        await player.dispose();
      } catch (_) {}
    }
  }

  Future<void> _stopPlayback() async {
    final player = _player;
    final done = _playbackDone;
    if (player == null) return;
    try {
      await player.stop();
    } catch (_) {}
    if (done != null && !done.isCompleted) done.complete();
  }

  /// Descobre quais áudios da equipe existem em assets/audio/ (uma vez só).
  Future<void> _loadClips() async {
    if (_clipsLoaded) return;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final asset in manifest.listAssets()) {
        if (!asset.startsWith(_assetPrefix)) continue;
        final fileName = asset.substring(_assetPrefix.length);
        final dot = fileName.lastIndexOf('.');
        if (dot <= 0) continue;
        final ext = fileName.substring(dot + 1).toLowerCase();
        if (!_audioExtensions.contains(ext)) continue;
        // AssetSource já adiciona o prefixo "assets/".
        _clips[fileName.substring(0, dot)] = 'audio/$fileName';
      }
    } catch (_) {
      // Sem manifesto: tudo cai na voz sintética.
    }
    _clipsLoaded = true;
  }

  // ---------------------------------------------------------------------------
  // Pastas e arquivos
  // ---------------------------------------------------------------------------

  Future<Directory> _root() async =>
      _baseDir ??= await getApplicationDocumentsDirectory();

  Future<Directory> _subDir(String name) async {
    final dir = Directory('${(await _root()).path}/$name');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _medAudioDir() async =>
      _medDir ??= await _subDir('med_audio');

  Future<Directory> _customVoiceDir() async =>
      _customDir ??= await _subDir('custom_voice');

  Future<void> _moveReplace(String sourcePath, String destPath) async {
    final source = File(sourcePath);
    if (!await source.exists()) return;
    final dest = File(destPath);
    if (await dest.exists()) await dest.delete();
    try {
      await source.rename(destPath);
    } on FileSystemException {
      await source.copy(destPath);
      await source.delete();
    }
  }

  // ---------------------------------------------------------------------------
  // Nome do medicamento gravado (tela de cadastro)
  // ---------------------------------------------------------------------------

  Future<String> _pathFor(int medicationId) async =>
      '${(await _medAudioDir()).path}/med_$medicationId.m4a';

  /// Caminho da gravação do medicamento, ou null se não houver.
  Future<String?> medicationAudioPath(int? medicationId) async {
    if (medicationId == null) return null;
    final path = await _pathFor(medicationId);
    return File(path).existsSync() ? path : null;
  }

  Future<void> deleteMedicationAudio(int medicationId) async {
    try {
      final file = File(await _pathFor(medicationId));
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Arquivo temporário para uma gravação que ainda não foi salva.
  Future<String> newTempRecordingPath() async =>
      '${(await _medAudioDir()).path}/pending_${DateTime.now().millisecondsSinceEpoch}.m4a';

  Future<void> saveMedicationAudio(int medicationId, String tempPath) async =>
      _moveReplace(tempPath, await _pathFor(medicationId));

  // ---------------------------------------------------------------------------
  // Voz personalizável: frases gravadas pelo usuário (tela "Minha voz")
  // ---------------------------------------------------------------------------

  Future<String> _customPathFor(String key) async =>
      '${(await _customVoiceDir()).path}/$key.m4a';

  Future<String?> customPhrasePath(String key) async {
    final path = await _customPathFor(key);
    return File(path).existsSync() ? path : null;
  }

  /// Chaves das frases que o usuário já gravou.
  Future<Set<String>> recordedCustomKeys() async {
    final keys = <String>{};
    try {
      final dir = await _customVoiceDir();
      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (!name.endsWith('.m4a') || name.startsWith('tmp_')) continue;
        keys.add(name.substring(0, name.length - 4));
      }
    } catch (_) {}
    return keys;
  }

  Future<String> newCustomTempPath(String key) async =>
      '${(await _customVoiceDir()).path}/tmp_$key.m4a';

  Future<void> saveCustomPhrase(String key, String tempPath) async =>
      _moveReplace(tempPath, await _customPathFor(key));

  Future<void> deleteCustomPhrase(String key) async {
    try {
      final file = File(await _customPathFor(key));
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Gravação
  // ---------------------------------------------------------------------------

  /// Começa a gravar em [path]. Retorna false se o microfone foi negado.
  Future<bool> startRecording(String path) async {
    if (!await _recorder.hasPermission()) return false;
    await stop();
    await _recorder.start(const RecordConfig(), path: path);
    return true;
  }

  /// Para a gravação e devolve o caminho do arquivo (ou null).
  Future<String?> stopRecording() => _recorder.stop();

  /// Cancela a gravação em andamento e apaga o arquivo.
  Future<void> cancelRecording() async {
    try {
      if (await _recorder.isRecording()) await _recorder.cancel();
    } catch (_) {}
  }
}
