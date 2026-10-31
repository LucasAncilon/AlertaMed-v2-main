import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _role = 'client';
  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _loading) return;

    setState(() => _loading = true);

    try {
      await AuthService().register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada com sucesso! Faça seu login.'),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível cadastrar: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Cadastro no AlertaMed',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Informe seu nome.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email)) {
                        return 'Informe um email válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        tooltip: _showPassword
                            ? 'Ocultar senha'
                            : 'Mostrar senha',
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (value) => value == null || value.length < 8
                        ? 'Use pelo menos 8 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: !_showPassword,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) => value != _passwordController.text
                        ? 'As senhas não coincidem.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tipo de conta',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  RadioGroup<String>(
                    groupValue: _role,
                    onChanged: (value) {
                      if (value != null && !_loading) {
                        setState(() => _role = value);
                      }
                    },
                    child: const Column(
                      children: [
                        RadioListTile<String>(
                          title: Text('Paciente'),
                          subtitle: Text(
                            'Pessoa que utiliza o AlertaMed para sua rotina.',
                          ),
                          value: 'client',
                        ),
                        RadioListTile<String>(
                          title: Text('Acompanhante'),
                          subtitle: Text(
                            'Pessoa que acompanha pacientes vinculados.',
                          ),
                          value: 'caregiver',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _register,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text('Criar conta'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
