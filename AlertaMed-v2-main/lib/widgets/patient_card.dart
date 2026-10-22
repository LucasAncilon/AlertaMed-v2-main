import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../theme/cores.dart';

class PatientCard extends StatelessWidget {
  final Patient? patient;
  final VoidCallback? onEdit;

  const PatientCard({super.key, required this.patient, this.onEdit});

  @override
  Widget build(BuildContext context) {
    if (patient == null) {
      return _buildEmpty(context);
    }
    return _buildCard(context, patient!);
  }

  Widget _buildCard(BuildContext context, Patient p) {
    return Semantics(
      label: 'Ficha da pessoa: ${p.name}, ${p.age} anos',
      child: Card(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        color: AppCores.primaria,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.age} anos${p.bloodType != null ? '  ·  ${p.bloodType}' : ''}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null)
                    Semantics(
                      label: 'Editar dados da pessoa',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.white70, size: 22),
                        onPressed: onEdit,
                        tooltip: 'Editar pessoa',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                ],
              ),
              if (_temDetalhes(p)) ...[
                const SizedBox(height: 10),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 10),
                if (p.allergies != null && p.allergies!.isNotEmpty)
                  _DetalheRow(
                      icon: Icons.warning_amber,
                      texto: 'Alergias: ${p.allergies}'),
                if (p.emergencyContact != null &&
                    p.emergencyContact!.isNotEmpty)
                  _DetalheRow(
                      icon: Icons.emergency,
                      texto: 'Emergência: ${p.emergencyContact}'),
                if (p.caregiverName != null && p.caregiverName!.isNotEmpty)
                  _DetalheRow(
                      icon: Icons.favorite,
                      texto: 'Cuidador(a): ${p.caregiverName}'
                          '${p.caregiverPhone != null && p.caregiverPhone!.isNotEmpty ? ' · ${p.caregiverPhone}' : ''}'),
              ],
              if (p.isDemo) ...[
                const SizedBox(height: 10),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 10),
                _DetalheRow(
                  icon: Icons.info_outline,
                  texto:
                      'Cadastro de exemplo — edite ou exclua para começar.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _temDetalhes(Patient p) =>
      (p.allergies != null && p.allergies!.isNotEmpty) ||
      (p.emergencyContact != null && p.emergencyContact!.isNotEmpty) ||
      (p.caregiverName != null && p.caregiverName!.isNotEmpty);

  Widget _buildEmpty(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: AppCores.superficie,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.person_outline,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nenhuma pessoa cadastrada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppCores.textoPrimario,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Adicione as informações da pessoa principal para facilitar o cuidado.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppCores.textoSecundario,
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      label: 'Cadastrar pessoa',
                      button: true,
                      child: TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: const Text(
                          'Cadastrar pessoa',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetalheRow extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _DetalheRow({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
