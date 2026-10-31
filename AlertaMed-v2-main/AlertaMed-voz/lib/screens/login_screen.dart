import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import 'authenticated_home_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _loading) return;

    setState(() => _loading = true);

    try {
      final result = await AuthService().login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final tokenSalvo = await TokenStorage().getToken();

      if (tokenSalvo == null || tokenSalvo.isEmpty) {
        throw Exception('Não foi possível recuperar o token salvo.');
      }

      if (!mounted) return;

      final user = result['user'] as Map<String, dynamic>;
      final name = user['name'] as String? ?? 'Usuário';
      final role = user['role'];

      if (role is! String || (role != 'client' && role != 'caregiver')) {
        throw Exception('Tipo de conta inválido.');
      }

      if (role != 'client' && role != 'caregiver') {
        throw Exception('Tipo de conta inválido.');
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AuthenticatedHomeScreen(userName: name, role: role),
        ),
      );

      // A navegação para a área autenticada será
      // implementada após testarmos o login no Android.
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar no AlertaMed')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.health_and_safety,
                      size: 80,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Bem-vindo de volta!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe seu email.';
                        }
                        if (!value.contains('@')) {
                          return 'Informe um email válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _showPassword
                              ? 'Ocultar senha'
                              : 'Mostrar senha',
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe sua senha.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          child: Text(
                            'Esqueci minha senha',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text(
                                'Entrar',
                                style: TextStyle(fontSize: 20),
                              ),
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
