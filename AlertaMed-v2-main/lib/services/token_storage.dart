import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tokenKey = 'alertamed_auth_token';

  // Salva o JWT após o login.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Recupera o JWT armazenado.
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Remove o JWT ao sair da conta.
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
