import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../utils/result.dart';

/// Cryptographic service for encrypting and decrypting data
class CryptoService {
  static const int _keyLength = 32; // 256 bits
  static const int _nonceLength = 12; // 96 bits for AES-GCM
  static const int _saltLength = 32; // 256 bits
  static const int _iterations = 100000; // PBKDF2 iterations

  final AesGcm _aesGcm = AesGcm.with256bits();
  final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _iterations,
    bits: _keyLength * 8,
  );

  /// Encrypt data with a password
  Future<Result<EncryptedData>> encrypt(String data, String password) async {
    try {
      // Generate random salt and nonce
      final salt = _generateRandomBytes(_saltLength);
      final nonce = _generateRandomBytes(_nonceLength);

      // Derive key from password using PBKDF2
      final secretKey = await _deriveKey(password, salt);

      // Encrypt the data
      final dataBytes = utf8.encode(data);
      final secretBox = await _aesGcm.encrypt(
        dataBytes,
        secretKey: secretKey,
        nonce: nonce,
      );

      // Combine salt, nonce, and encrypted data
      final encryptedData = EncryptedData(
        data: secretBox.cipherText,
        nonce: nonce,
        salt: salt,
        mac: secretBox.mac.bytes,
      );

      return Result.success(encryptedData);
    } catch (e) {
      return Result.error('Encryption failed', e);
    }
  }

  /// Decrypt data with a password
  Future<Result<String>> decrypt(EncryptedData encryptedData, String password) async {
    try {
      // Derive key from password using the stored salt
      final secretKey = await _deriveKey(password, encryptedData.salt);

      // Create SecretBox from encrypted data
      final secretBox = SecretBox(
        encryptedData.data,
        nonce: encryptedData.nonce,
        mac: Mac(encryptedData.mac),
      );

      // Decrypt the data
      final decryptedBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      final decryptedString = utf8.decode(decryptedBytes);
      return Result.success(decryptedString);
    } catch (e) {
      return Result.error('Decryption failed - invalid password or corrupted data', e);
    }
  }

  /// Encrypt data with a randomly generated key
  Future<Result<EncryptionResult>> encryptWithRandomKey(String data) async {
    try {
      // Generate random key and nonce
      final keyBytes = _generateRandomBytes(_keyLength);
      final nonce = _generateRandomBytes(_nonceLength);
      final secretKey = SecretKey(keyBytes);

      // Encrypt the data
      final dataBytes = utf8.encode(data);
      final secretBox = await _aesGcm.encrypt(
        dataBytes,
        secretKey: secretKey,
        nonce: nonce,
      );

      final result = EncryptionResult(
        encryptedData: EncryptedData(
          data: secretBox.cipherText,
          nonce: nonce,
          salt: Uint8List(0), // No salt needed for random key
          mac: secretBox.mac.bytes,
        ),
        key: keyBytes,
      );

      return Result.success(result);
    } catch (e) {
      return Result.error('Encryption with random key failed', e);
    }
  }

  /// Decrypt data with a provided key
  Future<Result<String>> decryptWithKey(EncryptedData encryptedData, Uint8List key) async {
    try {
      final secretKey = SecretKey(key);

      // Create SecretBox from encrypted data
      final secretBox = SecretBox(
        encryptedData.data,
        nonce: encryptedData.nonce,
        mac: Mac(encryptedData.mac),
      );

      // Decrypt the data
      final decryptedBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      final decryptedString = utf8.decode(decryptedBytes);
      return Result.success(decryptedString);
    } catch (e) {
      return Result.error('Decryption with key failed', e);
    }
  }

  /// Generate a secure random password
  String generatePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
  }) {
    const uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
    const numberChars = '0123456789';
    const symbolChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (includeUppercase) chars += uppercaseChars;
    if (includeLowercase) chars += lowercaseChars;
    if (includeNumbers) chars += numberChars;
    if (includeSymbols) chars += symbolChars;

    if (chars.isEmpty) {
      throw ArgumentError('At least one character type must be included');
    }

    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generate a cryptographically secure random key
  Uint8List generateKey() {
    return _generateRandomBytes(_keyLength);
  }

  /// Hash data using SHA-256
  Future<Uint8List> hash(String data) async {
    final sha256 = Sha256();
    final hash = await sha256.hash(utf8.encode(data));
    return Uint8List.fromList(hash.bytes);
  }

  /// Verify data against a hash
  Future<bool> verifyHash(String data, Uint8List hash) async {
    final computedHash = await this.hash(data);
    return listEquals(computedHash, hash);
  }

  /// Generate HMAC for data integrity
  Future<Uint8List> generateHmac(String data, Uint8List key) async {
    final hmac = Hmac.sha256();
    final secretKey = SecretKey(key);
    final mac = await hmac.calculateMac(
      utf8.encode(data),
      secretKey: secretKey,
    );
    return Uint8List.fromList(mac.bytes);
  }

  /// Verify HMAC
  Future<bool> verifyHmac(String data, Uint8List key, Uint8List expectedMac) async {
    final computedMac = await generateHmac(data, key);
    return listEquals(computedMac, expectedMac);
  }

  /// Derive key from password using PBKDF2
  Future<SecretKey> _deriveKey(String password, Uint8List salt) async {
    return await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  /// Generate cryptographically secure random bytes
  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (index) => random.nextInt(256)),
    );
  }

  /// Encode encrypted data to base64 for storage
  String encodeToBase64(EncryptedData encryptedData) {
    final combined = <int>[];
    
    // Add lengths as 4-byte integers
    combined.addAll(_intToBytes(encryptedData.salt.length));
    combined.addAll(_intToBytes(encryptedData.nonce.length));
    combined.addAll(_intToBytes(encryptedData.mac.length));
    combined.addAll(_intToBytes(encryptedData.data.length));
    
    // Add data
    combined.addAll(encryptedData.salt);
    combined.addAll(encryptedData.nonce);
    combined.addAll(encryptedData.mac);
    combined.addAll(encryptedData.data);
    
    return base64Encode(combined);
  }

  /// Decode encrypted data from base64
  Result<EncryptedData> decodeFromBase64(String encoded) {
    try {
      final bytes = base64Decode(encoded);
      int offset = 0;

      // Read lengths
      final saltLength = _bytesToInt(bytes.sublist(offset, offset + 4));
      offset += 4;
      final nonceLength = _bytesToInt(bytes.sublist(offset, offset + 4));
      offset += 4;
      final macLength = _bytesToInt(bytes.sublist(offset, offset + 4));
      offset += 4;
      final dataLength = _bytesToInt(bytes.sublist(offset, offset + 4));
      offset += 4;

      // Read data
      final salt = Uint8List.fromList(bytes.sublist(offset, offset + saltLength));
      offset += saltLength;
      final nonce = Uint8List.fromList(bytes.sublist(offset, offset + nonceLength));
      offset += nonceLength;
      final mac = Uint8List.fromList(bytes.sublist(offset, offset + macLength));
      offset += macLength;
      final data = Uint8List.fromList(bytes.sublist(offset, offset + dataLength));

      return Result.success(EncryptedData(
        data: data,
        nonce: nonce,
        salt: salt,
        mac: mac,
      ));
    } catch (e) {
      return Result.error('Failed to decode encrypted data', e);
    }
  }

  /// Convert int to 4 bytes (big-endian)
  List<int> _intToBytes(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  /// Convert 4 bytes to int (big-endian)
  int _bytesToInt(List<int> bytes) {
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }
}

/// Encrypted data container
class EncryptedData {
  final Uint8List data;
  final Uint8List nonce;
  final Uint8List salt;
  final Uint8List mac;

  const EncryptedData({
    required this.data,
    required this.nonce,
    required this.salt,
    required this.mac,
  });

  @override
  String toString() => 'EncryptedData(${data.length} bytes)';
}

/// Encryption result with key
class EncryptionResult {
  final EncryptedData encryptedData;
  final Uint8List key;

  const EncryptionResult({
    required this.encryptedData,
    required this.key,
  });

  @override
  String toString() => 'EncryptionResult(${encryptedData.data.length} bytes, ${key.length} byte key)';
}

/// Crypto service provider
final cryptoServiceProvider = Provider<CryptoService>((ref) {
  return CryptoService();
});

/// Utility functions for common crypto operations
class CryptoUtils {
  CryptoUtils._();

  /// Generate a secure random string
  static String generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generate a UUID-like string
  static String generateUuid() {
    final random = Random.secure();
    final bytes = List.generate(16, (index) => random.nextInt(256));
    
    // Set version (4) and variant bits
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Check password strength
  static PasswordStrength checkPasswordStrength(String password) {
    int score = 0;
    final feedback = <String>[];

    if (password.length >= 8) {
      score += 1;
    } else {
      feedback.add('Use at least 8 characters');
    }

    if (password.contains(RegExp(r'[A-Z]'))) {
      score += 1;
    } else {
      feedback.add('Include uppercase letters');
    }

    if (password.contains(RegExp(r'[a-z]'))) {
      score += 1;
    } else {
      feedback.add('Include lowercase letters');
    }

    if (password.contains(RegExp(r'[0-9]'))) {
      score += 1;
    } else {
      feedback.add('Include numbers');
    }

    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score += 1;
    } else {
      feedback.add('Include special characters');
    }

    if (password.length >= 12) {
      score += 1;
    }

    final strength = switch (score) {
      <= 2 => PasswordStrengthLevel.weak,
      3 => PasswordStrengthLevel.fair,
      4 => PasswordStrengthLevel.good,
      >= 5 => PasswordStrengthLevel.strong,
    };

    return PasswordStrength(strength, feedback);
  }
}

/// Password strength levels
enum PasswordStrengthLevel {
  weak,
  fair,
  good,
  strong;

  String get displayName => switch (this) {
    PasswordStrengthLevel.weak => 'Weak',
    PasswordStrengthLevel.fair => 'Fair',
    PasswordStrengthLevel.good => 'Good',
    PasswordStrengthLevel.strong => 'Strong',
  };
}

/// Password strength result
class PasswordStrength {
  final PasswordStrengthLevel level;
  final List<String> feedback;

  const PasswordStrength(this.level, this.feedback);

  @override
  String toString() => 'PasswordStrength(${level.displayName}, ${feedback.length} suggestions)';
}
