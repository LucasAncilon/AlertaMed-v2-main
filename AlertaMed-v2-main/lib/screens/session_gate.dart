import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'authenticated_home_screen.dart';
import 'welcome_screen.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<Map<String, dynamic>?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = AuthService().getAuthenticatedUser();
  }

  void _retry() {
    setState(() {
      _sessionFuture = AuthService().getAuthenticatedUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Não foi possível verificar sua sessão.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const WelcomeScreen();
        }

        return AuthenticatedHomeScreen(
          userName: user['name'] as String,
          role: user['role'] as String,
        );
      },
    );
  }
}
