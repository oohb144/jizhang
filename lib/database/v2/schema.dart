import 'package:sqflite/sqflite.dart';

class SchemaV2 {
  const SchemaV2._();

  static const int version = 1;

  static Future<void> create(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');

    await db.execute('''
      CREATE TABLE metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        opening_balance REAL NOT NULL DEFAULT 0,
        manual_adjustment REAL NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'CNY',
        icon TEXT,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_name TEXT,
        icon TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        type TEXT NOT NULL DEFAULT 'expense'
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT NOT NULL UNIQUE,
        total_amount REAL NOT NULL,
        daily_amount REAL,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE category_budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT NOT NULL,
        category_name TEXT NOT NULL,
        budget_amount REAL NOT NULL,
        used_amount REAL NOT NULL DEFAULT 0,
        created_at TEXT,
        UNIQUE(month, category_name)
      )
    ''');

    await db.execute('''
      CREATE TABLE ledger_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        destination_account_id INTEGER,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        subcategory TEXT,
        category_id INTEGER,
        merchant TEXT,
        payment_channel TEXT,
        note TEXT,
        source TEXT NOT NULL DEFAULT 'manual',
        auto_detected INTEGER NOT NULL DEFAULT 0,
        confidence REAL,
        source_fingerprint TEXT,
        raw_source_id TEXT,
        transaction_date TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY(account_id) REFERENCES accounts(id),
        FOREIGN KEY(destination_account_id) REFERENCES accounts(id),
        FOREIGN KEY(category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE merchant_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant_pattern TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        account_id INTEGER,
        payment_channel TEXT,
        priority INTEGER NOT NULL DEFAULT 0,
        learned_from_user INTEGER NOT NULL DEFAULT 0,
        enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(category_id) REFERENCES categories(id),
        FOREIGN KEY(account_id) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_captures (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL,
        merchant TEXT,
        payment_channel TEXT,
        direction TEXT,
        confidence REAL NOT NULL DEFAULT 0,
        source_package TEXT NOT NULL,
        source_fingerprint TEXT NOT NULL UNIQUE,
        received_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_transactions_account_date '
      'ON ledger_transactions(account_id, transaction_date)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_destination_date '
      'ON ledger_transactions(destination_account_id, transaction_date)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX idx_transactions_fingerprint '
      'ON ledger_transactions(source_fingerprint) '
      'WHERE source_fingerprint IS NOT NULL',
    );
    await db.execute(
      'CREATE INDEX idx_merchant_rules_priority '
      'ON merchant_rules(enabled, priority DESC)',
    );
  }
}
