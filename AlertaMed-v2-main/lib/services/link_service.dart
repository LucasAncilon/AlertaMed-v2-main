import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'token_storage.dart';

class LinkService {
  Future<Map<String, dynamic>> _request(
    String path, {
    bool post = false,
    Map<String, dynamic>? body,
  }) async {
    final token = await TokenStorage().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sessão não encontrada. Faça login novamente.');
    }

    final uri = Uri.parse('${AuthService.baseUrl}$path');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final http.Response response;

    if (post) {
      response = await http
          .post(uri, headers: headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 15));
    } else {
      response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Resposta inválida do servidor.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded['message'];
      throw Exception(
        message is String ? message : 'Erro HTTP ${response.statusCode}.',
      );
    }

    return decoded;
  }

  Future<Map<String, dynamic>> generateCode() {
    return _request('/auth/link-code', post: true);
  }

  Future<Map<String, dynamic>> useCode(String code) {
    return _request(
      '/auth/use-link-code',
      post: true,
      body: {'code': code.trim().toUpperCase()},
    );
  }

  Future<List<Map<String, dynamic>>> getLinkedClients() async {
    final data = await _request('/auth/linked-clients');
    final clients = data['clients'];

    if (clients is! List) {
      throw Exception('Lista de pacientes inválida.');
    }

    return clients.map((item) {
      if (item is! Map<String, dynamic>) {
        throw Exception('Dados de paciente inválidos.');
      }
      return item;
    }).toList();
  }
}
