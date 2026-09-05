import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import 'legacy_json_migrator.dart';

class DataStoreBootstrapResult {
  final AppDatabaseV2 database;
  final MigrationResult migration;

  const DataStoreBootstrapResult({
    required this.database,
    required this.migration,
  });
}

class DataStoreBootstrap {
  const DataStoreBootstrap._();

  static Future<DataStoreBootstrapResult> initialize({
    DatabaseFactory? factory,
    String? databasePath,
    File? legacyJsonFile,
  }) async {
    final database = await AppDatabaseV2.open(
      factory: factory,
      path: databasePath,
    );

    try {
      final source = legacyJsonFile ?? await _resolveLegacyJsonFile();
      final migration = await LegacyJsonMigrator(database.db).migrateIfNeeded(source);
      return DataStoreBootstrapResult(
        database: database,
        migration: migration,
      );
    } catch (_) {
      await database.close();
      rethrow;
    }
  }

  static Future<File> _resolveLegacyJsonFile() async {
    Directory baseDir;
    if (Platform.isAndroid || Platform.isIOS) {
      baseDir = await getApplicationDocumentsDirectory();
    } else {
      final home = Platform.environment['USERPROFILE'] ??
          Platform.environment['HOME'] ??
          '.';
      baseDir = Directory(home);
    }
    return File('${baseDir.path}/jizhang_data/data.json');
  }
}
