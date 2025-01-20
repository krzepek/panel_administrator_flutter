import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:panel_administrator_flutter/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class TokenService {
  static const String _tokenKey = 'jwt_token';
  static const String _secureSecret = secretKey;

  /// Save the JWT token to shared preferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Retrieve the JWT token from shared preferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final valid = await validateToken(token);
      if(valid) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getDecodedToken() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      return JwtDecoder.decode(token);
    } catch (e) {
      return null;
    }
  }

  Future<void> generateToken(String userId) async {
    final jwt = JWT({
      'userId': userId,
    });

    final token = jwt.sign(
      SecretKey(_secureSecret), 
      expiresIn: Duration(minutes: 30),
    );

    await saveToken(token);
  }

  Future<bool> validateToken(String token) async {
    try {
      JwtDecoder.decode(token);
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return false;
    }
  }

  Future<void> prolongToken() async {
    try {
      final token = await getToken();
      if (token == null) throw 'Token is invalid or expired';

      final payload = JwtDecoder.decode(token);
      if (!payload.containsKey('userId')) throw 'Invalid token structure';

      final jwt = JWT({
        ...payload,
      });

      final newToken = jwt.sign(
        SecretKey(_secureSecret),
        expiresIn: Duration(minutes: 30),
      );
      await saveToken(newToken);
    } catch (e) {
      throw 'Failed to prolong token: $e';
    }
  }
}