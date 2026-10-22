import 'dart:convert';

import 'package:http/http.dart' as http;
import 'token_storage.dart';

class AuthService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.78:3000',
  );

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do servidor.');
    }

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erro ao realizar login.');
    }

    if (data['token'] is! String || data['user'] is! Map<String, dynamic>) {
      throw Exception('Resposta de autenticação incompleta.');
    }

    final token = data['token'] as String;

    if (token.isEmpty) {
      throw Exception('Token de autenticação inválido.');
    }

    await TokenStorage().saveToken(token);

    return data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    if (role != 'client' && role != 'caregiver') {
      throw Exception('Tipo de conta inválido.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name.trim(),
            'email': email.trim(),
            'password': password,
            'role': role,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do servidor.');
    }

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Erro ao cadastrar usuário.');
    }

    if (data['user'] is! Map<String, dynamic>) {
      throw Exception('Resposta de cadastro incompleta.');
    }

    return data;
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do servidor.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        data['message'] ?? 'Erro ao solicitar recuperação de senha.',
      );
    }

    return data;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/reset-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'code': code.trim(),
            'newPassword': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do servidor.');
    }

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erro ao redefinir senha.');
    }

    return data;
  }

  Future<Map<String, dynamic>?> getAuthenticatedUser() async {
    final storage = TokenStorage();
    final token = await storage.getToken();

    // Não existe sessão armazenada.
    if (token == null || token.isEmpty) {
      return null;
    }

    final http.Response response;

    try {
      response = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Uma falha de conexão não deve apagar o JWT.
      rethrow;
    }

    // Token inválido, expirado ou usuário não encontrado.
    if (response.statusCode == 401) {
      await storage.deleteToken();
      return null;
    }

    // Outros erros do servidor não invalidam a sessão.
    if (response.statusCode != 200) {
      throw Exception('Não foi possível verificar a sessão.');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic> ||
        data['user'] is! Map<String, dynamic>) {
      throw Exception('Resposta de sessão inválida.');
    }

    final user = data['user'] as Map<String, dynamic>;

    if (user['id'] is! String ||
        user['name'] is! String ||
        (user['role'] != 'client' && user['role'] != 'caregiver')) {
      throw Exception('Dados do usuário inválidos.');
    }

    return user;
  }
}
