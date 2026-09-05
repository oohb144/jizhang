import 'package:sqflite/sqflite.dart';

import '../../models/pending_capture.dart';

class PendingCaptureRepository {
  final Database db;

  PendingCaptureRepository(this.db);

  Future<int> insertIfAbsent(PendingCapture capture) async {
    return db.insert(
      'pending_captures',
      capture.toDatabaseMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<PendingCapture>> getPending() async {
    final rows = await db.query(
      'pending_captures',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'received_at DESC, id DESC',
    );
    return rows.map(PendingCapture.fromMap).toList();
  }

  Future<int> countPending() async {
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM pending_captures WHERE status = 'pending'",
    );
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<void> markConfirmed(String fingerprint) async {
    await db.update(
      'pending_captures',
      {'status': 'confirmed'},
      where: 'source_fingerprint = ?',
      whereArgs: [fingerprint],
    );
  }

  Future<void> markIgnored(String fingerprint) async {
    await db.update(
      'pending_captures',
      {'status': 'ignored'},
      where: 'source_fingerprint = ?',
      whereArgs: [fingerprint],
    );
  }
}
