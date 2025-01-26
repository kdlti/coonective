import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:xxtea/xxtea.dart';

// A classe ApiSecurity fornece métodos para realizar operações de criptografia e geração de valores aleatórios.
class ApiSecurity {
  // Gera uma string aleatória de letras minúsculas com o tamanho especificado.
  static String randomLetters(int length) {
    String text = "";
    const String possible = "abcdefghijklmnopqrstuvwxyz";
    final rng = Random();
    for (var i = 0; i < length; i++) {
      text += (possible[rng.nextInt(possible.length)]).toString();
    }
    return text;
  }

  // Gera uma string aleatória de números com o tamanho especificado.
  static String randomNumbers(int length) {
    String text = "";
    const String possible = "0123456789";
    final rng = Random();
    for (var i = 0; i < length; i++) {
      text += (possible[rng.nextInt(possible.length)]).toString();
    }
    return text;
  }

  // Gera uma string aleatória de bytes com o tamanho especificado.
  static String randomBytes(int length) {
    String text = "";
    const String possible = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_";
    final rng = Random();
    for (var i = 0; i < length; i++) {
      text += (possible[rng.nextInt(possible.length)]).toString();
    }
    return text;
  }

  // Codifica uma string em base64URL.
  static String base64URLEncode(String str) {
    return base64Url.encode(utf8.encode(str)).replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
  }

  // Codifica uma string usando SHA-256.
  static String encodeSha256(String value) {
    List<int> subject = utf8.encode(value);
    return sha256.convert(subject).toString();
  }

  // Codifica uma string usando SHA-1.
  static String encodeSha1(String value) {
    List<int> subject = utf8.encode(value);
    return sha1.convert(subject).toString();
  }

  // Codifica uma string usando MD5.
  static String encodeMD5(String value) {
    List<int> subject = utf8.encode(value);
    return md5.convert(subject).toString();
  }

  // Criptografa uma string usando XXTEA com a senha fornecida.
  static String? encrypt(String? value, String password) {
    if (value != null && password.isNotEmpty) {
      value = xxtea.encryptToString(value, password);
    }
    return value;
  }

  // Descriptografa uma string criptografada usando XXTEA com a senha fornecida.
  static String? decrypt(String? value, String password) {
    if (value != null && password.isNotEmpty) {
      value = xxtea.decryptToString(value, password);
    }
    return value;
  }

  // Gera um UID no formato "XXXX-XXXX-XXXX-XXXX".
  static String uid() {
    String text = "";
    int length = 16;
    const String possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final rng = Random();
    for (var i = 0; i < length; i++) {
      text += (possible[rng.nextInt(possible.length)]).toString();
    }

    return "${text.substring(0, 4)}-${text.substring(4, 8)}-${text.substring(8, 12)}-${text.substring(12,
            text.length)}";
  }

// Gera um UID no formato "XXXX-XXXX-XXXX-XXXX" com base em uma string de entrada,
// codificando-a usando SHA-1 e convertendo-a em maiúsculas.
  static String uidSha1(String text) {
    text = encodeSha1(text).toUpperCase();
    return "${text.substring(0, 4)}-${text.substring(4, 8)}-${text.substring(8, 12)}-${text.substring(12, 16)}";
  }
}