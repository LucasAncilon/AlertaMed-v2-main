import 'package:flutter/material.dart';
import '../theme/cores.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../services/auth_service.dart';
import 'authenticated_home_screen.dart';
import '../services/voice_service.dart';
import '../widgets/narrate_on_open.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NarrateOnOpen(
      parts: const [
        VoicePart(
          'Bem-vindo ao AlertaMed. Aplicativo para organizar seus medicamentos. '
          'Toque em Começar para entrar, ou em Criar conta para se cadastrar.',
          clip: 'boas_vindas',
        ),
      ],
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppCores.saude,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.health_and_safety,
                              size: 60,
                              color: AppCores.saude,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'AlertaMed',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: AppCores.primaria,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Autonomia e Organização da Saúde',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: AppCores.textoSecundario,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const _DividerDecorado(),
                          const SizedBox(height: 24),
                          const Text(
                            'Organize seus medicamentos, acompanhe horários e simplifique o cuidado com a saúde de forma acessível e segura.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: AppCores.textoPrimario,
                              height: 1.65,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Desenvolvido com foco em pessoas com baixa visão.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppCores.textoSecundario,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Começar a usar o AlertaMed',
                button: true,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final user = await AuthService().getAuthenticatedUser();

                      if (!context.mounted) return;

                      if (user == null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                        return;
                      }

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AuthenticatedHomeScreen(
                            userName: user['name'] as String,
                            role: user['role'] as String,
                          ),
                        ),
                      );
                    } catch (error) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Não foi possível verificar sua sessão. Tente novamente.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Começar'),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Criar uma nova conta no AlertaMed',
                button: true,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('Criar conta'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _DividerDecorado extends StatelessWidget {
  const _DividerDecorado();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppCores.primaria.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.medication,
            size: 20,
            color: AppCores.saude.withValues(alpha: 0.6),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppCores.primaria.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
