import 'package:flutter/material.dart';
import '../services/token_storage.dart';
import 'welcome_screen.dart';
import 'link_screen.dart';
import 'audio_settings_screen.dart';

class AuthenticatedHomeScreen extends StatelessWidget {
  final String userName;
  final String role;

  const AuthenticatedHomeScreen({
    super.key,
    required this.userName,
    required this.role,
  });

  Future<void> _logout(BuildContext context) async {
    try {
      await TokenStorage().deleteToken();

      final tokenRestante = await TokenStorage().getToken();

      if (tokenRestante != null) {
        throw Exception('O token ainda está armazenado.');
      }

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível sair da conta. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClient = role == 'client';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AlertaMed'),
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Voltar para o início',
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isClient ? Icons.person : Icons.people,
                      size: 90,
                      color: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Olá, $userName!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isClient
                          ? 'Você entrou como Paciente.'
                          : 'Você entrou como acompanhante.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Autenticação realizada com sucesso.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LinkScreen(role: role),
                        ),
                      ),
                      icon: Icon(isClient ? Icons.link : Icons.people),
                      label: Text(
                        isClient
                            ? 'Gerar código de vínculo'
                            : 'Gerenciar Pacientes',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AudioSettingsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.settings),
                      label: const Text(
                        'Configurações de áudio',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Sair da conta',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
