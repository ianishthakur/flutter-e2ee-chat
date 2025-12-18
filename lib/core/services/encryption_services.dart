import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;

class EncryptionService {
  // Derives a 256-bit encryption key from the PIN using PBKDF2
  Uint8List _deriveKey(String pin) {
    // Use a fixed salt for the same PIN to generate the same key
    // In production, consider using a per-room salt
    final salt = utf8.encode('e2ee-chat-salt-v1');

    // PBKDF2 with 10000 iterations
    final generator = PBKDF2KeyDerivation(macAlgorithm: sha256);

    final derivedKey = generator.deriveKey(
      secretKey: utf8.encode(pin),
      salt: salt,
      outputLength: 32, // 256 bits
    );

    return Uint8List.fromList(derivedKey);
  }

  /// Encrypts a message using AES-256-CBC
  String encrypt(String plainText, String pin) {
    try {
      final key = encrypt_pkg.Key(_deriveKey(pin));
      final iv = encrypt_pkg.IV.fromSecureRandom(
        16,
      );

      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc),
      );

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Combine IV and ciphertext for transmission
      // Format: base64(IV) + ":" + base64(ciphertext)
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypts a message using AES-256-CBC
  String decrypt(String encryptedText, String pin) {
    try {
      // Split IV and ciphertext
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted message format');
      }

      final iv = encrypt_pkg.IV.fromBase64(parts[0]);
      final encrypted = encrypt_pkg.Encrypted.fromBase64(parts[1]);

      final key = encrypt_pkg.Key(_deriveKey(pin));
      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc),
      );

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed - Wrong PIN or corrupted message');
    }
  }
}

/// PBKDF2 Key Derivation
class PBKDF2KeyDerivation {
  final Hash macAlgorithm;

  PBKDF2KeyDerivation({required this.macAlgorithm});

  List<int> deriveKey({
    required List<int> secretKey,
    required List<int> salt,
    required int outputLength,
    int iterations = 10000,
  }) {
    final blockCount = (outputLength / 32).ceil();
    final output = <int>[];

    for (var i = 1; i <= blockCount; i++) {
      output.addAll(_deriveBlock(secretKey, salt, iterations, i));
    }

    return output.sublist(0, outputLength);
  }

  List<int> _deriveBlock(
    List<int> secretKey,
    List<int> salt,
    int iterations,
    int blockIndex,
  ) {
    final hmac = Hmac(macAlgorithm, secretKey);

    var block = hmac.convert([...salt, ...intToBytes(blockIndex)]).bytes;
    var result = List<int>.from(block);

    for (var i = 1; i < iterations; i++) {
      block = hmac.convert(block).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= block[j];
      }
    }

    return result;
  }

  List<int> intToBytes(int value) {
    return [
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
  }
}
