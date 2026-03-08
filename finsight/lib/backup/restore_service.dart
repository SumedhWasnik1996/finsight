import 'dart:convert';
  import 'dart:typed_data';
  import 'dart:io';
  import 'package:encrypt/encrypt.dart' as enc;
  import 'package:file_picker/file_picker.dart';
  import 'package:pointycastle/export.dart';
  import '../core/database_helper.dart';

  class RestoreService {

    static Uint8List _deriveKey(String password, Uint8List salt) {
      final params = Pbkdf2Parameters(salt, 100000, 32);
      final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
      pbkdf2.init(params);
      return pbkdf2.process(utf8.encode(password) as Uint8List);
    }

    // ── Let user pick a .finsightbak file, decrypt, restore ─────────
    static Future<RestoreResult> restoreBackup(String password) async {
      // 1. Open file picker
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['finsightbak']);
      if (result == null || result.files.single.path == null) {
        return RestoreResult(success: false,
            message: 'No file selected');
      }

      try {
        final fileBytes =
            await File(result.files.single.path!).readAsBytes();

        // 2. Split: salt (16) | IV (12) | ciphertext (rest)
        final salt      = fileBytes.sublist(0, 16);
        final ivBytes   = fileBytes.sublist(16, 28);
        final cipher    = fileBytes.sublist(28);

        // 3. Derive key and decrypt
        final keyBytes  = _deriveKey(password, Uint8List.fromList(salt));
        final key        = enc.Key(Uint8List.fromList(keyBytes));
        final iv         = enc.IV(Uint8List.fromList(ivBytes));
        final encrypter  = enc.Encrypter(
            enc.AES(key, mode: enc.AESMode.gcm));
        final plaintext  = encrypter.decrypt(
            enc.Encrypted(Uint8List.fromList(cipher)), iv: iv);

        // 4. Parse JSON
        final data = jsonDecode(plaintext) as Map<String,dynamic>;

        // 5. Write into the SQLite database
        final db = await DatabaseHelper.database;
        await db.transaction((txn) async {
          await txn.delete('transactions');
          await txn.delete('budgets');
          await txn.delete('monthly_snapshots');
          for (final r in (data['transactions'] as List))
            await txn.insert('transactions', r as Map<String,dynamic>,
                conflictAlgorithm: 5);
          for (final r in (data['budgets'] as List))
            await txn.insert('budgets', r as Map<String,dynamic>,
                conflictAlgorithm: 5);
          for (final r in (data['snapshots'] as List))
            await txn.insert('monthly_snapshots',
                r as Map<String,dynamic>, conflictAlgorithm: 5);
        });
        final txCount = (data['transactions'] as List).length;
        return RestoreResult(success: true,
            message: 'Restored \$txCount transactions successfully.');

      } catch (e) {
        return RestoreResult(success: false,
            message: 'Decryption failed. Wrong password or corrupted file.');
      }
    }
  }

  class RestoreResult {
    final bool   success;
    final String message;
    RestoreResult({required this.success, required this.message});
  }
