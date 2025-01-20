import 'package:encrypt/encrypt.dart' as encrypt;
import '../config.dart';

class EncryptionUtil {
  static final _key = encrypt.Key.fromUtf8(hashKey);
  static final _iv = encrypt.IV.fromUtf8(hashKey.substring(0, 16));
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));

  static String encryptPassword(String password) {
    try {
      if (password.isEmpty) {
        throw ArgumentError("Password cannot be empty");
      }
      final encrypted = _encrypter.encrypt(password, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print("Encryption Error: $e");
      return "";
    }
  }

  static String decryptPassword(String encryptedPassword) {
    try {
      if (encryptedPassword.isEmpty) {
        throw ArgumentError("Encrypted password cannot be empty");
      }
      final decrypted = _encrypter.decrypt64(encryptedPassword, iv: _iv);
      return decrypted;
    } catch (e) {
      print("Decryption Error: $e");
      return "";
    }
  }
}
