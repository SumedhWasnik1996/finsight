  import 'dart:convert';
  import 'dart:math';
  import 'dart:typed_data';
  import 'package:encrypt/encrypt.dart' as enc;
  import 'package:path_provider/path_provider.dart';
  import 'package:share_plus/share_plus.dart';
  import 'dart:io';
  import 'package:pointycastle/export.dart';
  import '../core/constants.dart';
  import '../core/database_helper.dart';

  class BackupService {

    // ── Derive AES key from password using PBKDF2 ───────────────────
    static Uint8List _deriveKey(String password, Uint8List salt) {
      final params = Pbkdf2Parameters(salt, 100000, 32);
      final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
      pbkdf2.init(params);
      return pbkdf2.process(utf8.encode(password) as Uint8List);
    }

    // ── Export: read DB, encrypt, save as .finsightbak ──────────────
    static Future<String> exportBackup(String password) async {
      final db = await DatabaseHelper.database;

      // Gather all data
      final transactions = await db.query('transactions');
      final budgets      = await db.query('budgets');
      final snapshots    = await db.query('monthly_snapshots');

      final payload = jsonEncode({
        'version':      1,
        'exported_at':  DateTime.now().toIso8601String(),
        'transactions': transactions,
        'budgets':      budgets,
        'snapshots':    snapshots,
      });

      // Generate random salt and IV
      final rand = Random.secure();
      final salt = Uint8List.fromList(
          List.generate(16, (_) => rand.nextInt(256)));
      final iv   = enc.IV.fromSecureRandom(12); // 12 bytes for GCM

      // Derive key and encrypt
      final keyBytes = _deriveKey(password, salt);
      final key       = enc.Key(keyBytes);
      final encrypter = enc.Encrypter(
          enc.AES(key, mode: enc.AESMode.gcm));
      final encrypted = encrypter.encrypt(payload, iv: iv);

      // Build file: 16-byte salt | 12-byte IV | ciphertext
      final fileBytes = Uint8List(
          salt.length + iv.bytes.length + encrypted.bytes.length);
      fileBytes.setAll(0, salt);
      fileBytes.setAll(salt.length, iv.bytes);
      fileBytes.setAll(salt.length + iv.bytes.length, encrypted.bytes);

      // Save to temp directory then share
      final dir  = await getApplicationDocumentsDirectory();
      final ts   = DateTime.now()
          .toIso8601String().replaceAll(':','-').substring(0,19);
      final path = '\${dir.path}/finsight_backup_\$ts'
                   '\${AppConstants.backupExtension}';
      await File(path).writeAsBytes(fileBytes);

      // Open the share sheet so user can save or send the file
      await Share.shareXFiles([XFile(path)],
          text: 'FinSight Backup \$ts');

      return path;
    }
  }
