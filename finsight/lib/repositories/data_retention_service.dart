import 'package:shared_preferences/shared_preferences.dart';
  import '../core/database_helper.dart';
  import '../core/constants.dart';

  class DataRetentionService {

    static Future<int> getRetentionMonths() async {
      final p = await SharedPreferences.getInstance();
      return p.getInt(AppConstants.keyRetentionMonths)
          ?? AppConstants.defaultRetentionMonths;
    }

    static Future<void> setRetentionMonths(int months) async {
      final p = await SharedPreferences.getInstance();
      await p.setInt(AppConstants.keyRetentionMonths, months);
    }

    /// Called automatically every time the app starts.
    static Future<PurgeResult> runPurge() async {
      final months  = await getRetentionMonths();
      final db      = await DatabaseHelper.database;
      final cutoff  = DateTime.now().subtract(
                        Duration(days: months * 30));
      final cutoffS = cutoff.toIso8601String().substring(0, 10);

      // 1. Snapshot monthly totals before deleting
      await _snapshot(db, cutoffS);

      // 2. Delete old transactions
      final deleted = await db.delete('transactions',
          where: 'date < ?', whereArgs: [cutoffS]);

      return PurgeResult(deleted, cutoff);
    }

    // Save category totals so charts work after purge
    static Future<void> _snapshot(dynamic db, String cutoff) async {
      final rows = await db.rawQuery('''
        SELECT substr(date,1,7) AS ym, category,
               SUM(amount) AS tot, COUNT(*) AS cnt
        FROM transactions WHERE date < ?
        GROUP BY ym, category
      ''', [cutoff]);
      for (final r in rows) {
        await db.insert('monthly_snapshots', {
          'id':         '\${r['ym']}_\${r['category']}',
          'year_month': r['ym'],
          'category':   r['category'],
          'total_spent':r['tot'],
          'tx_count':   r['cnt'],
        }, conflictAlgorithm: 5); // REPLACE
      }
    }
  }

  class PurgeResult {
    final int deletedCount;
    final DateTime cutoffDate;
    PurgeResult(this.deletedCount, this.cutoffDate);
  }
