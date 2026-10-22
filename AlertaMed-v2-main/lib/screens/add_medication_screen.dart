import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../models/medication.dart';
import '../services/voice_service.dart';
import '../theme/cores.dart' show AppCores;
import '../widgets/medication_voice_recorder.dart';
import '../widgets/narrate_on_open.dart';

class AddMedicationScreen extends StatefulWidget {
  final Medication? medication;
  final int patientId;

  const AddMedicationScreen({super.key, this.medication, this.patientId = 1});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _scheduleController;
  late final TextEditingController _frequencyController;
  late final TextEditingController _notesController;

  final _picker = ImagePicker();
  final _voiceCtrl = MedicationVoiceController();

  String? _photoPath;
  String _originalPhotoPath = '';
  TimeOfDay? _notificationTime;
  bool _voiceReminder = false;
  bool _saving = false;

  bool get _isEdit => widget.medication != null;

  @override
  void initState() {
    super.initState();
    final m = widget.medication;
    _nameController = TextEditingController(text: m?.name ?? '');
    _dosageController = TextEditingController(text: m?.dosage ?? '');
    _scheduleController = TextEditingController(text: m?.schedule ?? '');
    _frequencyController = TextEditingController(text: m?.frequency ?? '');
    _notesController = TextEditingController(text: m?.notes ?? '');

    if (m != null) {
      _photoPath = m.photoPath.isNotEmpty ? m.photoPath : null;
      _originalPhotoPath = m.photoPath;
      _voiceReminder = m.voiceReminder;
      if (m.notificationTime.isNotEmpty) {
        final parts = m.notificationTime.split(':');
        if (parts.length == 2) {
          final h = int.tryParse(parts[0]);
          final min = int.tryParse(parts[1]);
          if (h != null && min != null) {
            _notificationTime = TimeOfDay(hour: h, minute: min);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _scheduleController.dispose();
    _frequencyController.dispose();
    _notesController.dispose();
    _voiceCtrl.discard();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (image == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'med_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destPath = '${dir.path}/$fileName';
    await File(image.path).copy(destPath);

    setState(() => _photoPath = destPath);
  }

  Future<void> _removePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover foto?', style: TextStyle(fontSize: 20)),
        content: const Text(
          'Deseja remover a foto da embalagem?',
          style: TextStyle(fontSize: 18),
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
    if (confirmed == true) {
      setState(() => _photoPath = null);
    }
  }

  Future<void> _pickNotificationTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _notificationTime ?? TimeOfDay.now(),
      helpText: 'Horário do lembrete',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time != null) setState(() => _notificationTime = time);
  }

  void _clearNotificationTime() {
    setState(() {
      _notificationTime = null;
      _voiceReminder = false;
    });
  }

  String get _notificationTimeLabel {
    if (_notificationTime == null) return 'Sem lembrete';
    final h = _notificationTime!.hour.toString().padLeft(2, '0');
    final m = _notificationTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _notificationTimeString {
    if (_notificationTime == null) return '';
    final h = _notificationTime!.hour.toString().padLeft(2, '0');
    final m = _notificationTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // Limpa foto antiga se foi substituída ou removida
    if (_originalPhotoPath.isNotEmpty && _originalPhotoPath != (_photoPath ?? '')) {
      final oldFile = File(_originalPhotoPath);
      if (await oldFile.exists()) await oldFile.delete();
    }

    final medication = Medication(
      id: widget.medication?.id,
      patientId: widget.medication?.patientId ?? widget.patientId,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      schedule: _scheduleController.text.trim(),
      frequency: _frequencyController.text.trim(),
      notes: _notesController.text.trim(),
      photoPath: _photoPath ?? '',
      notificationTime: _notificationTimeString,
      voiceReminder: _notificationTime != null && _voiceReminder,
    );

    final db = DatabaseHelper();
    final int medId;
    if (_isEdit) {
      await db.updateMedication(medication);
      medId = medication.id!;
    } else {
      medId = await db.insertMedication(medication);
    }
    await _voiceCtrl.commit(medId);

    VoiceService().say('Medicamento salvo.', clip: 'medicamento_salvo');
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return NarrateOnOpen(
      parts: [
        _isEdit
            ? const VoicePart('Editar medicamento.',
                clip: 'tela_editar_medicamento')
            : const VoicePart(
                'Novo medicamento. Preencha o nome, a dosagem e os horários. '
                'Você também pode gravar o nome do remédio com a sua voz.',
                clip: 'tela_novo_medicamento'),
      ],
      child: Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar Medicamento' : 'Novo Medicamento'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit
                    ? 'Atualize os dados do medicamento'
                    : 'Preencha os dados do medicamento',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),

              // --- Campos de texto ---
              _CampoTexto(
                controller: _nameController,
                label: 'Nome do medicamento',
                hint: 'Ex: Losartana',
                icone: Icons.medication,
                obrigatorio: true,
              ),
              const SizedBox(height: 16),
              _CampoTexto(
                controller: _dosageController,
                label: 'Dosagem',
                hint: 'Ex: 50mg',
                icone: Icons.local_pharmacy,
                obrigatorio: true,
              ),
              const SizedBox(height: 16),
              _CampoTexto(
                controller: _scheduleController,
                label: 'Horário(s)',
                hint: 'Ex: 08:00 e 20:00',
                icone: Icons.access_time,
                obrigatorio: true,
              ),
              const SizedBox(height: 16),
              _CampoTexto(
                controller: _frequencyController,
                label: 'Frequência (opcional)',
                hint: 'Ex: 1x ao dia, 2x ao dia, A cada 8h',
                icone: Icons.repeat,
                obrigatorio: false,
              ),
              const SizedBox(height: 16),
              _CampoTexto(
                controller: _notesController,
                label: 'Observações (opcional)',
                hint: 'Ex: Tomar com água',
                icone: Icons.notes,
                obrigatorio: false,
                maxLines: 3,
              ),

              const SizedBox(height: 28),

              // --- Foto da embalagem ---
              _SecaoTitulo(icone: Icons.photo_camera, titulo: 'Foto da embalagem'),
              const SizedBox(height: 12),
              _PhotoSection(
                photoPath: _photoPath,
                onPickCamera: () => _pickImage(ImageSource.camera),
                onPickGallery: () => _pickImage(ImageSource.gallery),
                onRemove: _removePhoto,
              ),

              const SizedBox(height: 28),

              // --- Voz do medicamento ---
              _SecaoTitulo(icone: Icons.mic, titulo: 'Nome com a sua voz'),
              const SizedBox(height: 12),
              MedicationVoiceRecorder(
                controller: _voiceCtrl,
                medicationId: widget.medication?.id,
              ),

              const SizedBox(height: 28),

              // --- Lembretes ---
              _SecaoTitulo(icone: Icons.notifications_outlined, titulo: 'Lembrete'),
              const SizedBox(height: 12),
              _NotificationSection(
                timeLabel: _notificationTimeLabel,
                hasTime: _notificationTime != null,
                voiceReminder: _voiceReminder,
                onPickTime: _pickNotificationTime,
                onClearTime: _clearNotificationTime,
                onVoiceToggle: _notificationTime != null
                    ? (val) => setState(() => _voiceReminder = val)
                    : null,
              ),

              const SizedBox(height: 36),

              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save, size: 24),
                label: Text(_saving
                    ? 'Salvando...'
                    : _isEdit
                        ? 'Salvar alterações'
                        : 'Salvar Medicamento'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  ),
    );
  }
}

// --- Subwidgets ---

class _SecaoTitulo extends StatelessWidget {
  final IconData icone;
  final String titulo;

  const _SecaoTitulo({required this.icone, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 22, color: AppCores.primaria),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppCores.textoPrimario,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoSection extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onRemove;

  const _PhotoSection({
    required this.photoPath,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;

    return Container(
      height: hasPhoto ? 140 : null,
      constraints: hasPhoto ? null : const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: hasPhoto
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(photoPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image_outlined,
                        size: 48, color: Colors.grey),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Semantics(
                    label: 'Remover foto',
                    button: true,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.close,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PhotoButton(
                  icone: Icons.camera_alt,
                  label: 'Câmera',
                  onTap: onPickCamera,
                ),
                Container(width: 1, height: 60, color: Colors.grey.shade300),
                _PhotoButton(
                  icone: Icons.photo_library,
                  label: 'Galeria',
                  onTap: onPickGallery,
                ),
              ],
            ),
    );
  }
}

class _PhotoButton extends StatelessWidget {
  final IconData icone;
  final String label;
  final VoidCallback onTap;

  const _PhotoButton({
    required this.icone,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Selecionar foto da $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 36, color: AppCores.primaria),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(fontSize: 15, color: AppCores.primaria)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final String timeLabel;
  final bool hasTime;
  final bool voiceReminder;
  final VoidCallback onPickTime;
  final VoidCallback onClearTime;
  final ValueChanged<bool>? onVoiceToggle;

  const _NotificationSection({
    required this.timeLabel,
    required this.hasTime,
    required this.voiceReminder,
    required this.onPickTime,
    required this.onClearTime,
    required this.onVoiceToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Linha: horário do lembrete
            Row(
              children: [
                Icon(
                  hasTime
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  size: 24,
                  color: hasTime ? AppCores.primaria : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Horário do lembrete',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: hasTime ? AppCores.primaria : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasTime)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: onClearTime,
                    tooltip: 'Remover lembrete',
                  ),
                TextButton(
                  onPressed: onPickTime,
                  child: Text(hasTime ? 'Alterar' : 'Definir'),
                ),
              ],
            ),
            // Linha: lembrete por voz
            Opacity(
              opacity: hasTime ? 1.0 : 0.4,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  Icons.volume_up_outlined,
                  size: 24,
                  color: voiceReminder && hasTime ? const Color(0xFF388E3C) : Colors.grey,
                ),
                title: const Text('Lembrete por voz',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                subtitle: const Text(
                  'Fala o nome e dosagem ao tocar no lembrete',
                  style: TextStyle(fontSize: 13),
                ),
                value: voiceReminder,
                onChanged: onVoiceToggle,
                activeThumbColor: const Color(0xFF388E3C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icone;
  final bool obrigatorio;
  final int maxLines;

  const _CampoTexto({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icone,
    required this.obrigatorio,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icone, size: 26),
      ),
      validator: obrigatorio
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Este campo é obrigatório';
              }
              return null;
            }
          : null,
    );
  }
}
