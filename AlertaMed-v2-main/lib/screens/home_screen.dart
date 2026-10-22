import 'dart:io';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/medication.dart';
import '../models/patient.dart';
import '../services/notification_service.dart';
import '../services/tts_service.dart';
import '../services/voice_service.dart';
import '../widgets/patient_card.dart';
import 'add_medication_screen.dart';
import 'audio_settings_screen.dart';
import 'patient_form_screen.dart';

class HomeScreen extends StatefulWidget {
  final Patient patient;

  const HomeScreen({super.key, required this.patient});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Medication> _medications = [];
  late Patient _patient;
  bool _loading = true;
  bool _narrated = false;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _loadData();
  }

  Future<void> _loadData() async {
    if (_patient.id == null) return;
    final meds = await _db.getMedicationsByPatient(_patient.id!);

    final ns = NotificationService();
    await ns.cancelAll();
    for (final med in meds) {
      if (med.notificationTime.isNotEmpty) {
        await ns.schedule(med, patientName: _patient.name);
      }
    }

    setState(() {
      _medications = meds;
      _loading = false;
    });

    // Narra a tela só na primeira vez que ela carrega.
    if (!_narrated && mounted) {
      _narrated = true;
      _narrateScreen(meds);
    }
  }

  void _narrateScreen(List<Medication> meds) {
    final allergies = _patient.allergies;
    VoiceService().speakSequence([
      const VoicePart('Tela de medicamentos.', clip: 'tela_medicamentos'),
      VoicePart('${_patient.name}.'),
      if (allergies != null && allergies.isNotEmpty)
        VoicePart('Atenção. Alergias: $allergies.'),
      if (meds.isEmpty)
        const VoicePart('Nenhum medicamento cadastrado ainda.',
            clip: 'nenhum_medicamento')
      else
        VoicePart(meds.length == 1
            ? 'Você tem um medicamento cadastrado.'
            : 'Você tem ${meds.length} medicamentos cadastrados.'),
      const VoicePart(
          'Toque em um medicamento para ouvir. '
          'O botão com o sinal de mais, no canto da tela, adiciona um novo.',
          clip: 'dica_medicamentos'),
    ]);
  }

  Future<void> _deleteMedication(Medication med) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover medicamento?', style: TextStyle(fontSize: 20)),
        content: Text(
          'Deseja remover "${med.name}" da lista?',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover',
                style: TextStyle(fontSize: 18, color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && med.id != null) {
      await NotificationService().cancel(med.id!);
      await VoiceService().deleteMedicationAudio(med.id!);
      if (med.photoPath.isNotEmpty) {
        final file = File(med.photoPath);
        if (await file.exists()) await file.delete();
      }
      await _db.deleteMedication(med.id!);
      _loadData();
      VoiceService().say('Medicamento removido.', clip: 'medicamento_removido');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${med.name}" removido.')),
        );
      }
    }
  }

  Future<void> _navegarParaCadastro() async {
    final adicionou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicationScreen(patientId: _patient.id ?? 1),
      ),
    );
    if (adicionou == true) _loadData();
  }

  Future<void> _editarMedicamento(Medication med) async {
    final editado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddMedicationScreen(medication: med)),
    );
    if (editado == true) _loadData();
  }

  void _toggleSound() {
    final tts = TtsService();
    tts.soundEnabled = !tts.soundEnabled;
    if (!tts.soundEnabled) {
      tts.stop();
      VoiceService().stop();
    } else {
      VoiceService().say('Som ativado.', clip: 'som_ativado');
    }
    setState(() {});
  }

  Future<void> _navegarParaPaciente() async {
    final updated = await Navigator.push<Patient?>(
      context,
      MaterialPageRoute(builder: (_) => PatientFormScreen(patient: _patient)),
    );
    if (updated != null) {
      setState(() => _patient = updated);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AlertaMed'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AudioSettingsScreen()),
            ),
            icon: const Icon(Icons.settings, size: 28),
            tooltip: 'Configurações de áudio',
          ),
          Semantics(
            label: TtsService().soundEnabled
                ? 'Som ativo. Toque para silenciar.'
                : 'Som silenciado. Toque para ativar.',
            button: true,
            child: IconButton(
              onPressed: _toggleSound,
              icon: Icon(
                TtsService().soundEnabled ? Icons.volume_up : Icons.volume_off,
                size: 28,
                color: TtsService().soundEnabled
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFEF5350),
              ),
              tooltip: TtsService().soundEnabled ? 'Silenciar som' : 'Ativar som',
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarParaCadastro,
        tooltip: 'Adicionar medicamento',
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildBody() {
    final temAlergias = _patient.allergies != null &&
        _patient.allergies!.isNotEmpty;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PatientCard(patient: _patient, onEdit: _navegarParaPaciente),
        ),
        if (temAlergias)
          SliverToBoxAdapter(
            child: _AllergyAlert(allergies: _patient.allergies!),
          ),
        if (_medications.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEstadoVazio(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 88),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final med = _medications[index];
                  return _MedicationCard(
                    medication: med,
                    onTap: () => VoiceService().speakMedication(med),
                    onEdit: () => _editarMedicamento(med),
                    onDelete: () => _deleteMedication(med),
                  );
                },
                childCount: _medications.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEstadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_outlined,
                size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            const Text(
              'Nenhum medicamento\ncadastrado ainda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text(
              'Toque no botão + para\ncadastrar o primeiro medicamento.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllergyAlert extends StatelessWidget {
  final String allergies;

  const _AllergyAlert({required this.allergies});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Atenção: alergias da pessoa: $allergies',
      child: Card(
        color: const Color(0xFFFFF8E1),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF8F00),
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ALERGIAS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE65100),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      allergies,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicationCard({
    required this.medication,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  void _showDetails(BuildContext context) {
    final hasPhoto = medication.photoPath.isNotEmpty &&
        File(medication.photoPath).existsSync();
    final imgHeight =
        (MediaQuery.of(context).size.height * 0.50).clamp(200.0, 420.0);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasPhoto)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(medication.photoPath),
                    width: double.infinity,
                    height: imgHeight,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) => _iconFallback(ctx),
                  ),
                )
              else
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication,
                    size: 72,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                ),
              const SizedBox(height: 20),
              Semantics(
                header: true,
                child: Text(
                  medication.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                medication.dosage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fechar', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconFallback(BuildContext context) => Icon(
        Icons.medication,
        size: 72,
        color: Theme.of(context).colorScheme.primary,
      );

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        medication.photoPath.isNotEmpty && File(medication.photoPath).existsSync();
    final hasNotif = medication.notificationTime.isNotEmpty;

    return Semantics(
      label:
          'Medicamento: ${medication.name}, dosagem: ${medication.dosage}, horário: ${medication.schedule}. Toque para ouvir e ver detalhes.',
      child: Card(
        child: InkWell(
          onTap: () {
            onTap(); // TTS: speakIdentification
            _showDetails(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MedThumbnail(photoPath: hasPhoto ? medication.photoPath : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(medication.name,
                                style: Theme.of(context).textTheme.titleMedium),
                          ),
                          if (hasNotif) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message:
                                  'Lembrete às ${medication.notificationTime}',
                              child: const Icon(
                                Icons.alarm,
                                size: 18,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      _InfoRow(label: 'Dosagem', value: medication.dosage),
                      _InfoRow(label: 'Horário', value: medication.schedule),
                      if (hasNotif)
                        _InfoRow(
                            label: 'Lembrete',
                            value: medication.notificationTime),
                      if (medication.frequency.isNotEmpty)
                        _InfoRow(
                            label: 'Frequência', value: medication.frequency),
                      if (medication.notes.isNotEmpty)
                        _InfoRow(label: 'Obs.', value: medication.notes),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      label: 'Editar ${medication.name}',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 22, color: Color(0xFF1565C0)),
                        onPressed: onEdit,
                        tooltip: 'Editar medicamento',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      label: 'Remover ${medication.name}',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 22, color: Colors.red),
                        onPressed: onDelete,
                        tooltip: 'Remover medicamento',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MedThumbnail extends StatelessWidget {
  final String? photoPath;

  const _MedThumbnail({this.photoPath});

  @override
  Widget build(BuildContext context) {
    if (photoPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(photoPath!),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _defaultIcon(context),
        ),
      );
    }
    return _defaultIcon(context);
  }

  Widget _defaultIcon(BuildContext context) {
    return Icon(
      Icons.medication,
      size: 48,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Color(0xFF555555)),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
