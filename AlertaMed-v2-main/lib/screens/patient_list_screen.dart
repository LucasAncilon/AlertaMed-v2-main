import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/patient.dart';
import '../theme/cores.dart';
import '../services/voice_service.dart';
import '../widgets/narrate_on_open.dart';
import 'home_screen.dart';
import 'patient_form_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final _db = DatabaseHelper();
  List<Patient> _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _loading = true);
    final patients = await _db.getPatients();
    setState(() {
      _patients = patients;
      _loading = false;
    });
  }

  Future<void> _abrirPaciente(Patient patient) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(patient: patient)),
    );
    _loadPatients();
  }

  Future<void> _novoPaciente() async {
    final patient = await Navigator.push<Patient?>(
      context,
      MaterialPageRoute(builder: (_) => const PatientFormScreen()),
    );
    if (patient != null && mounted) {
      await _abrirPaciente(patient);
    } else {
      _loadPatients();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NarrateOnOpen(
      parts: const [
        VoicePart(
          'Tela de pessoas. Toque em uma pessoa para ver os medicamentos, '
          'ou no botão Nova pessoa para cadastrar.',
          clip: 'tela_pessoas',
        ),
      ],
      child: Scaffold(
      appBar: AppBar(title: const Text('Pessoas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novoPaciente,
        icon: const Icon(Icons.person_add, size: 28),
        label: const Text('Nova pessoa'),
        tooltip: 'Cadastrar nova pessoa',
      ),
    ),
    );
  }

  Widget _buildBody() {
    if (_patients.isEmpty) return _buildEstadoVazio();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: _patients.length,
      itemBuilder: (_, i) => _PatientTile(
        patient: _patients[i],
        onTap: () => _abrirPaciente(_patients[i]),
      ),
    );
  }

  Widget _buildEstadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            const Text(
              'Nenhuma pessoa\ncadastrada ainda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text(
              'Toque em "Nova pessoa" para\ncomeçar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const _PatientTile({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pessoa: ${patient.name}, ${patient.age} anos',
      button: true,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppCores.primaria,
                  child: const Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${patient.age} anos'
                        '${patient.bloodType != null ? '  ·  ${patient.bloodType}' : ''}',
                        style: const TextStyle(
                            fontSize: 15, color: AppCores.textoSecundario),
                      ),
                      if (patient.isDemo) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFCC02)),
                          ),
                          child: const Text(
                            'Exemplo · edite ou exclua para começar',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF8D6E00)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppCores.textoSecundario),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
