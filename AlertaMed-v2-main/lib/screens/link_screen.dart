import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/link_service.dart';

class LinkScreen extends StatefulWidget {
  final String role;

  const LinkScreen({super.key, required this.role});

  @override
  State<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  final _service = LinkService();
  final _codeController = TextEditingController();

  bool _loading = false;
  String? _generatedCode;
  DateTime? _expiresAt;
  List<Map<String, dynamic>> _clients = [];

  bool get _isClient => widget.role == 'client';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _generateCode() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final result = await _service.generateCode();

      if (!mounted) return;

      setState(() {
        _generatedCode = result['code'] as String;
        _expiresAt = DateTime.tryParse(
          result['expiresAt']?.toString() ?? '',
        )?.toLocal();
      });

      _showMessage('Código gerado com sucesso!');
    } catch (error) {
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useCode() async {
    if (_loading) return;

    final code = _codeController.text.trim().toUpperCase();

    if (!RegExp(r'^[A-HJ-NP-Z2-9]{8}$').hasMatch(code)) {
      _showMessage('Digite um código válido de 8 caracteres.');
      return;
    }

    setState(() => _loading = true);

    try {
      await _service.useCode(code);

      if (!mounted) return;

      _codeController.clear();
      _showMessage('Paciente vinculado com sucesso!');
      await _loadClients();
    } catch (error) {
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadClients() async {
    try {
      final clients = await _service.getLinkedClients();

      if (!mounted) return;
      setState(() => _clients = clients);
    } catch (error) {
      _showMessage(_errorMessage(error));
    }
  }

  @override
  void initState() {
    super.initState();

    if (!_isClient) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadClients();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isClient ? 'Código de vínculo' : 'Meus pacientes'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_isClient) ...[
              const Icon(Icons.link, size: 64),
              const SizedBox(height: 20),
              const Text(
                'Vincular acompanhante',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Gere um código e informe ao acompanhante '
                'que deseja autorizar.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _generateCode,
                child: const Text('Gerar código de vínculo'),
              ),
              if (_generatedCode != null) ...[
                const SizedBox(height: 24),
                SelectableText(
                  _generatedCode!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: _generatedCode!),
                    );
                    _showMessage('Código copiado.');
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar código'),
                ),
                const Text(
                  'Código de uso único, válido por 15 minutos.',
                  textAlign: TextAlign.center,
                ),
                if (_expiresAt != null)
                  Text(
                    'Expira às '
                    '${_expiresAt!.hour.toString().padLeft(2, '0')}:'
                    '${_expiresAt!.minute.toString().padLeft(2, '0')}',
                    textAlign: TextAlign.center,
                  ),
              ],
            ] else ...[
              const Text(
                'Vincular um paciente',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                decoration: const InputDecoration(
                  labelText: 'Código de vínculo',
                  hintText: 'Digite os 8 caracteres',
                  border: OutlineInputBorder(),
                ),
              ),
              ElevatedButton(
                onPressed: _loading ? null : _useCode,
                child: const Text('Vincular paciente'),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pacientes vinculados',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Atualizar lista',
                    onPressed: _loading ? null : _loadClients,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_clients.isEmpty)
                const Text(
                  'Nenhum paciente exibido. Atualize a lista '
                  'ou vincule um paciente.',
                  style: TextStyle(fontSize: 16),
                ),
              ..._clients.map(
                (client) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(client['name']?.toString() ?? 'Paciente'),
                    subtitle: const Text('Paciente vinculado'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
