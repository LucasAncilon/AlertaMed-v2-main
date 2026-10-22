import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/voice_phrases.dart';
import '../services/voice_service.dart';
import '../theme/cores.dart';
import '../widgets/narrate_on_open.dart';
import 'custom_voice_screen.dart';

/// Configurações de áudio: escolha de qual voz o aplicativo usa.
class AudioSettingsScreen extends StatefulWidget {
  const AudioSettingsScreen({super.key});

  @override
  State<AudioSettingsScreen> createState() => _AudioSettingsScreenState();
}

class _AudioSettingsScreenState extends State<AudioSettingsScreen> {
  final _voice = VoiceService();

  VoiceMode _mode = VoiceMode.padrao;
  int _developerClips = 0;
  int _customCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _voice.loadSettings();
    final clips = await _voice.developerClipCount();
    final custom = await _voice.recordedCustomKeys();
    if (!mounted) return;
    setState(() {
      _mode = _voice.mode;
      _developerClips = clips;
      _customCount = custom.length;
      _loading = false;
    });
  }

  Future<void> _refreshCustomCount() async {
    final custom = await _voice.recordedCustomKeys();
    if (!mounted) return;
    setState(() => _customCount = custom.length);
  }

  Future<void> _select(VoiceMode mode) async {
    if (mode == _mode) return;
    await _voice.setMode(mode);
    if (!mounted) return;
    setState(() => _mode = mode);

    switch (mode) {
      case VoiceMode.padrao:
        _voice.say('Voz padrão selecionada.');
      case VoiceMode.desenvolvedores:
        _voice.say('Voz dos desenvolvedores selecionada.');
      case VoiceMode.personalizada:
        if (_customCount == 0) {
          // Ainda não gravou nada: já abre a tela de gravação.
          await _openCustomVoice();
        } else {
          _voice.say('Voz personalizável selecionada.');
        }
    }
  }

  Future<void> _openCustomVoice() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomVoiceScreen()),
    );
    await _refreshCustomCount();
  }

  void _playExample() {
    _voice.speakReminder(
      const Medication(name: 'Losartana', dosage: '50 miligramas', schedule: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NarrateOnOpen(
      parts: const [
        VoicePart(
          'Configurações de áudio. Escolha a voz do aplicativo.',
          clip: 'tela_configuracoes_audio',
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Configurações de áudio')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                top: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    Semantics(
                      header: true,
                      child: const Text(
                        'Voz do aplicativo',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppCores.textoPrimario,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Escolha como o aplicativo fala com você.',
                      style: TextStyle(
                          fontSize: 18, color: AppCores.textoSecundario),
                    ),
                    const SizedBox(height: 12),
                    _VoiceOptionCard(
                      icon: Icons.phone_android,
                      title: 'Voz padrão do aplicativo',
                      description: 'Usa a voz do seu celular.',
                      selected: _mode == VoiceMode.padrao,
                      onTap: () => _select(VoiceMode.padrao),
                    ),
                    _VoiceOptionCard(
                      icon: Icons.record_voice_over,
                      title: 'Voz dos desenvolvedores',
                      description: 'Usa a voz gravada pela equipe do AlertaMed.',
                      selected: _mode == VoiceMode.desenvolvedores,
                      onTap: () => _select(VoiceMode.desenvolvedores),
                      extra: _mode == VoiceMode.desenvolvedores &&
                              _developerClips == 0
                          ? const Text(
                              'As gravações da equipe ainda não foram '
                              'adicionadas ao aplicativo. Por enquanto, será '
                              'usada a voz padrão.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF8D6E00),
                              ),
                            )
                          : null,
                    ),
                    _VoiceOptionCard(
                      icon: Icons.mic,
                      title: 'Voz personalizável',
                      description: 'Grave as frases do aplicativo com a sua voz.',
                      selected: _mode == VoiceMode.personalizada,
                      onTap: () => _select(VoiceMode.personalizada),
                      extra: _mode == VoiceMode.personalizada
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '$_customCount de ${kVoicePhrases.length} '
                                  'frases gravadas. As frases que você não '
                                  'gravar usam a voz padrão.',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _openCustomVoice,
                                  icon: const Icon(Icons.mic, size: 26),
                                  label: const Text('Gravar minhas frases'),
                                ),
                              ],
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _playExample,
                      icon: const Icon(Icons.volume_up, size: 26),
                      label: const Text('Ouvir exemplo',
                          style: TextStyle(fontSize: 18)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'O nome de cada remédio gravado no cadastro do '
                      'medicamento é usado em qualquer uma das vozes.',
                      style: TextStyle(
                          fontSize: 15, color: AppCores.textoSecundario),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _VoiceOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final Widget? extra;

  const _VoiceOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppCores.primaria : Colors.grey.shade300,
          width: selected ? 3 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              selected: selected,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Icon(icon, size: 36, color: AppCores.primaria),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: const TextStyle(
                                fontSize: 16, color: AppCores.textoSecundario),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 30,
                      color: selected ? AppCores.primaria : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            if (extra != null) ...[
              const SizedBox(height: 14),
              extra!,
            ],
          ],
        ),
      ),
    );
  }
}
