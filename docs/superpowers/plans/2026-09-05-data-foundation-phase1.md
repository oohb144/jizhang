# Smart Bookkeeping V2 Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace JSON as the long-term source of truth with a tested SQLite data foundation while preserving current user data and introducing auditable account/transaction models.

**Architecture:** Keep the current Flutter UI operational while adding the V2 domain models and SQLite repository in parallel. Migrate `jizhang_data/data.json` into SQLite in one transaction, retain the JSON file as backup, and derive balances from opening balance plus ledger entries instead of mutating a stored balance directly.

**Tech Stack:** Flutter/Dart 3.12+, `sqflite ^2.4.3`, `sqflite_common_ffi ^2.4.2+1` for unit tests, existing `path`/`path_provider` packages.

**Spec:** `docs/superpowers/specs/2026-09-05-smart-bookkeeping-v2-design.md`

## Global Constraints

- Core bookkeeping must remain local-first and usable without AI or a network connection.
- Existing `jizhang_data/data.json` must be preserved and migration must be idempotent.
- Account displayed balance must be derived from opening balance, manual adjustments and ledger transactions.
- Transfers between owned accounts must not count as income or expense.
- No Root, Xposed, accessibility automation, traffic interception or payment-app private database access.
- Phase 1 must not remove the legacy JSON helper until SQLite parity is verified.

---

### Task 1: Formalize V2 account and transaction domain models

**Files:**
- Modify: `lib/models/account.dart`
- Modify: `lib/models/transaction.dart`
- Create: `lib/models/merchant_rule.dart`
- Create: `lib/services/ledger_balance_calculator.dart`
- Create: `test/services/ledger_balance_calculator_test.dart`

**Interfaces:**
- Produces: `AccountType`, `TransactionType`, `TransactionSource`, `MerchantRule`, and `LedgerBalanceCalculator.balanceForAccount(...)`.

- [ ] Write failing tests proving expense, income, transfer-in, transfer-out and adjustment affect an account balance correctly.
- [ ] Run `flutter test test/services/ledger_balance_calculator_test.dart` and verify failure is caused by missing V2 model/calculator behavior.
- [ ] Add backward-compatible model fields and the minimal pure-Dart balance calculator.
- [ ] Re-run the focused test and then `flutter test`.
- [ ] Commit the green change.

### Task 2: Add SQLite schema and repositories without switching the UI

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/database/v2/app_database.dart`
- Create: `lib/database/v2/schema.dart`
- Create: `lib/database/v2/account_repository.dart`
- Create: `lib/database/v2/transaction_repository.dart`
- Create: `lib/database/v2/merchant_rule_repository.dart`
- Create: `test/database/v2/app_database_test.dart`

**Interfaces:**
- Produces: `AppDatabaseV2.open({DatabaseFactory? factory, String? path})`, account/transaction CRUD and derived-balance queries.

- [ ] Write failing in-memory SQLite tests for schema creation, inserting an account, posting expense/income/transfer records, editing/deleting a transaction, and derived balances.
- [ ] Run focused tests and confirm RED.
- [ ] Add `sqflite` and `sqflite_common_ffi`, schema version 1, foreign keys, indexes and repository implementations.
- [ ] Run focused tests and all Flutter tests until GREEN.
- [ ] Commit the green change.

### Task 3: Implement idempotent JSON-to-SQLite migration

**Files:**
- Create: `lib/database/v2/legacy_json_migrator.dart`
- Create: `test/database/v2/legacy_json_migrator_test.dart`

**Interfaces:**
- Produces: `LegacyJsonMigrator.migrateIfNeeded(...) -> MigrationResult`.

- [ ] Write failing fixture tests covering accounts, categories, budgets, category budgets and transactions from the legacy JSON shape.
- [ ] Verify a second migration call inserts zero duplicates and original JSON remains unchanged.
- [ ] Implement migration inside one SQLite transaction with metadata key `legacy_json_migration_v1`.
- [ ] Validate record counts and total opening/transaction amounts before marking migration complete.
- [ ] Run focused tests and all tests until GREEN, then commit.

### Task 4: Add CI verification for Flutter analysis and tests

**Files:**
- Create: `.github/workflows/flutter-ci.yml`

**Interfaces:**
- Produces: branch/PR checks for `flutter pub get`, `flutter analyze`, and `flutter test`.

- [ ] Add CI workflow using stable Flutter compatible with Dart >= 3.12.2.
- [ ] Push a test-first RED commit before Task 1 production code and verify the workflow fails for the intended missing behavior.
- [ ] Push production implementation and verify the workflow becomes GREEN.
- [ ] Keep the PR in draft until Phase 1 tests are green.

### Task 5: Integrate SQLite initialization behind a safe compatibility boundary

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/database/v2/data_store_bootstrap.dart`
- Create: `test/database/v2/data_store_bootstrap_test.dart`

**Interfaces:**
- Produces: `DataStoreBootstrap.initialize()` which opens SQLite, attempts legacy migration, and returns a V2 store handle; migration failure must not delete or modify legacy JSON.

- [ ] Write failing tests for first-run database creation, successful migration and migration rollback behavior.
- [ ] Implement bootstrap without deleting `DatabaseHelper` or changing existing screen APIs yet.
- [ ] Verify all tests and analyzer output are green.
- [ ] Commit and update Draft PR with Phase 1 status.
