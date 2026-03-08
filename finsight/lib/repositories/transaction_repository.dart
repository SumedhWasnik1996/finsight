import 'package:uuid/uuid.dart';
  import '../core/database_helper.dart';
  import '../models/transaction.dart';
  import '../services/categorisation_service.dart';

  class TransactionRepository {
    static const _uuid = Uuid();

    // Insert a batch of raw API transactions, skip duplicates
    static Future<int> insertBatch(
        List<Map<String,dynamic>> raw, String accountId) async {
      final db = await DatabaseHelper.database;
      int inserted = 0;
      for (final tx in raw) {
        final merchant = tx['description'] ??
                         tx['merchant_name'] ?? 'Unknown';
        final r = await db.insert('transactions', {
          'id':             _uuid.v4(),
          'account_id':     accountId,
          'transaction_id': tx['transaction_id'],
          'merchant':       merchant,
          'amount':         (tx['amount'] as num).abs().toDouble(),
          'currency':       tx['currency'] ?? 'GBP',
          'category':       CategorizationService.categorize(merchant),
          'date':           tx['timestamp'].toString().substring(0,10),
          'is_subscription':0,
          'created_at':     DateTime.now().toIso8601String(),
        }, conflictAlgorithm: 5); // IGNORE duplicates
        if (r > 0) inserted++;
      }
      return inserted;
    }

    static Future<List<FinTransaction>> getThisMonth() async {
      final db   = await DatabaseHelper.database;
      final from = '\${DateTime.now().year}-'
                   '\${DateTime.now().month.toString().padLeft(2,'0')}-01';
      final rows = await db.query('transactions',
          where: 'date >= ?', whereArgs: [from],
          orderBy: 'date DESC');
      return rows.map(FinTransaction.fromMap).toList();
    }

    static Future<Map<String,double>> getMonthlySummary() async {
      final db   = await DatabaseHelper.database;
      final from = '\${DateTime.now().year}-'
                   '\${DateTime.now().month.toString().padLeft(2,'0')}-01';
      final rows = await db.rawQuery('''
        SELECT category, SUM(amount) AS total
        FROM transactions WHERE date >= ?
        GROUP BY category ORDER BY total DESC
      ''', [from]);
      return {for (final r in rows)
        r['category'] as String: (r['total'] as num).toDouble()};
    }

    // Return ALL transactions (used by backup)
    static Future<List<Map<String,dynamic>>> getAllRaw() async {
      final db = await DatabaseHelper.database;
      return db.query('transactions', orderBy: 'date DESC');
    }
  }
