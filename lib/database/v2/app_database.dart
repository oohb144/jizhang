import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

class AppDatabaseV2 {
  final Database db;

  AppDatabaseV2._(this.db);

  static Future<AppDatabaseV2> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final selectedFactory = factory ?? databaseFactory;
    final databasePath = path ?? p.join(await getDatabasesPath(), 'jizhang_v2.db');

    final db = await selectedFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: SchemaV2.version,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) => SchemaV2.create(db),
      ),
    );

    return AppDatabaseV2._(db);
  }

  Future<void> close() => db.close();
}
