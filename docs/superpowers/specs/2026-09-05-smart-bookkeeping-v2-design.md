# Jizhang Smart Bookkeeping V2 — Architecture Design

Date: 2026-09-05
Status: Proposed for implementation
Target branch: `feat/smart-bookkeeping-v2`

## 1. Goal

Upgrade the existing Flutter personal finance app into a local-first Android smart bookkeeping app with:

- multi-account / wallet balance management;
- monthly bills and historical statistics;
- total and category budgets;
- automatic transaction capture from payment notifications;
- merchant learning and transaction deduplication;
- optional AI-assisted financial analysis;
- privacy-first local storage and explicit user control over data sent to AI providers.

The current Flutter UI and finance domain remain the product foundation. Android-native Kotlin code is introduced only for capabilities Flutter cannot reliably provide by itself, primarily `NotificationListenerService`.

## 2. Product Principles

1. **Local first** — core bookkeeping, statistics, budgets, balances, parsing and deduplication work without an account or cloud server.
2. **AI is advisory** — AI never decides whether money actually moved. It analyzes already-recorded data and may suggest categories or budget adjustments.
3. **Least privilege** — V1 uses notification access only for automatic capture. No Root, Xposed, payment-app private database access, traffic interception or password capture.
4. **Human confirmation for uncertainty** — low-confidence captures enter a confirmation flow instead of silently changing balances.
5. **Payment channel and funding account are separate concepts** — e.g. WeChat Pay can be the channel while ICBC debit card is the funding account.
6. **Existing user data must be migratable** — current JSON data is imported into the new database on first upgraded launch.

## 3. High-Level Architecture

```text
Payment app notifications
        |
        v
Android Kotlin native layer
NotificationListenerService
        |
        v
Native payment parser
(amount / merchant / direction / channel / confidence)
        |
        v
Flutter MethodChannel/EventChannel bridge
        |
        v
Pending capture pipeline
        |
        +--> deduplication
        +--> merchant rules
        +--> account matching
        +--> confidence policy
        |
        v
Transaction repository
        |
        +--> account balance views
        +--> budget usage
        +--> monthly statistics
        +--> AI analytics snapshots
```

## 4. Technology Choices

### Flutter layer

Retain Flutter/Dart for:

- application navigation;
- account and wallet UI;
- transaction lists;
- manual bookkeeping;
- budget management;
- charts and monthly summaries;
- AI analysis UI;
- privacy settings and provider configuration.

### Android native layer

Use Kotlin for:

- `NotificationListenerService`;
- package allowlist filtering;
- extraction of title/text/subtext from Android notifications;
- payment notification parser rules;
- native listener-health status;
- forwarding parsed candidates to Flutter.

### Local database

Replace the long-term JSON store with SQLite through a Flutter database package. The database becomes the single source of truth.

JSON remains only as a migration/import format and optional backup/export format.

## 5. Core Data Model

### Account

Fields:

- `id`
- `name`
- `type`: cash / wechat / alipay / bankCard / creditCard / campusCard / other
- `openingBalance`
- `manualAdjustment`
- `currency`
- `icon`
- `isArchived`
- `createdAt`
- `updatedAt`

The displayed balance is derived from opening balance, manual adjustments and posted transactions rather than blindly mutating a single balance field. This prevents balance drift when transactions are edited or deleted.

### Transaction

Fields:

- `id`
- `type`: expense / income / transfer / adjustment
- `amount`
- `categoryId`
- `accountId`
- `destinationAccountId` for transfers
- `merchant`
- `paymentChannel`
- `note`
- `occurredAt`
- `source`: manual / notification / import
- `autoDetected`
- `confidence`
- `sourceFingerprint`
- `rawSourceId` optional local reference
- `createdAt`
- `updatedAt`

### Category

Retain the existing parent/subcategory structure and custom icons.

### Budget

Retain the existing hierarchy:

- subcategory budget editable;
- parent-category budget derived from children;
- monthly total budget derived from category totals.

Store budgets by month so historical budgets remain reproducible.

### MerchantRule

Fields:

- `id`
- `merchantPattern`
- `categoryId`
- optional `accountId`
- optional `paymentChannel`
- `priority`
- `learnedFromUser`
- `enabled`

A user correction can create or update a merchant rule so future captures become more accurate without cloud AI.

### PendingCapture

Low-confidence or incomplete native captures are stored separately before posting a financial transaction.

Fields include:

- parsed amount;
- merchant;
- payment channel;
- direction;
- confidence;
- source package;
- source fingerprint;
- received timestamp.

Pending captures do **not** affect balances or budgets until confirmed.

## 6. Automatic Capture Pipeline

### Supported V1 source classes

- WeChat payment notifications;
- Alipay payment notifications;
- UnionPay notifications;
- payment-related bank-app notifications;
- selected e-commerce payment confirmations when the wording is explicit.

### Processing steps

1. Android receives a notification.
2. The package must be on the payment-source allowlist.
3. Extract visible notification fields only.
4. Normalize currency, amount and text.
5. Parser returns a candidate containing amount, direction, merchant, channel and confidence.
6. Generate a deterministic source fingerprint.
7. Flutter checks recent captures/transactions for duplicates.
8. Apply merchant rules and account matching.
9. High-confidence candidates are posted automatically if auto-post is enabled.
10. Low-confidence candidates go to confirmation.

### Deduplication

Deduplication considers:

- amount;
- direction;
- normalized merchant;
- payment channel;
- nearby timestamps;
- source fingerprint.

Cross-channel cases such as a WeChat payment notification and a bank debit notification should be recognized as a probable single transaction rather than two expenses.

## 7. Account Matching

Payment channel is not equivalent to funding account.

Examples:

- channel = WeChat, account = WeChat balance;
- channel = WeChat, account = ICBC debit card;
- channel = Alipay, account = Alipay balance;
- channel = Alipay, account = CCB debit card.

Matching order:

1. explicit account/card identifier parsed from notification;
2. user-defined channel-to-account rule;
3. user-defined default account for that payment channel;
4. unresolved -> confirmation flow.

Transfers between owned accounts create a paired transfer record and must not count as income or expense in spending statistics.

## 8. Balance Model

Account balances are computed from ledger history:

```text
current balance
= opening balance
+ income
- expense
+ incoming transfers
- outgoing transfers
+ manual adjustments
```

Benefits:

- editing an old transaction automatically fixes balances;
- deleting a mistaken capture reverses its effect;
- historical balances can be reconstructed;
- account totals remain auditable.

## 9. Monthly Bills and Statistics

The app must provide:

- current and historical month selection;
- income, expense and net cash flow;
- category breakdown;
- account breakdown;
- payment-channel breakdown;
- merchant ranking;
- daily spending trend;
- budget utilization;
- comparison with previous month;
- projected month-end spending using deterministic local statistics.

AI is not required for these baseline statistics.

## 10. AI Analysis

### Purpose

AI assists with interpretation, not transaction truth.

Supported questions include:

- Where did my money mainly go this month?
- Why did I spend more than last month?
- Am I likely to exceed my budget?
- Which categories should I reduce if I want to save a target amount?
- Summarize my month in plain language.
- Identify unusual spending patterns.

### Privacy modes

#### Mode A — Local only (default)

No AI network requests. All statistics work locally.

#### Mode B — Privacy summary

Send only aggregated, sanitized statistics such as category totals, month-over-month changes, budget values and anonymous merchant groups.

Do not send raw notification text, card identifiers or user notes.

#### Mode C — Detailed analysis

Explicit opt-in. Selected transaction details may be sent after a clear preview of what will leave the device.

### Provider abstraction

The Flutter layer exposes an `AiProvider` interface so the app can support:

- OpenAI;
- OpenAI-compatible APIs;
- custom base URL;
- configurable model.

Secrets must use platform secure storage / Android Keystore-backed storage and must never be committed to Git.

### AI safety rules

- AI output is a suggestion, not a financial fact.
- AI cannot directly create, delete or modify transactions without explicit user action.
- AI cannot change balances or budgets silently.
- Calculations shown in core statistics should be produced locally and passed to AI as structured facts.

## 11. Main Navigation

Recommended primary destinations:

1. **Home** — total assets, monthly income/expense, budget status, account cards, recent transactions.
2. **Bills** — month switcher, search, category/account/channel filters, transaction detail.
3. **Record** — expense, income, transfer and balance adjustment.
4. **Assets** — account list, balances, account history and account settings.
5. **Budget** — monthly and category budget management.
6. **AI** — monthly summary, trend explanations, budget advice and free-form questions.

Settings contains automatic capture permissions, listener health, matching rules, merchant learning, AI provider/privacy settings, backup/export and import.

## 12. Migration Strategy

The existing project stores user data in `jizhang_data/data.json`.

On first launch after SQLite adoption:

1. check whether the new database has completed migration;
2. locate existing JSON data;
3. parse accounts, categories, budgets and transactions;
4. insert them inside one database transaction;
5. validate record counts and key totals;
6. mark migration complete;
7. retain the original JSON file as a backup rather than deleting it.

Migration must be idempotent.

## 13. Security and Permissions

V1 automatic capture requires notification-listener access only.

Explicitly out of scope for V1:

- Root;
- Xposed;
- runtime hooking of WeChat or Alipay;
- network traffic interception;
- reading private payment-app databases;
- accessibility automation;
- payment-password capture.

The app should maintain a package allowlist and ignore unrelated notifications.

Raw notification text should not be retained by default after parsing. A diagnostic setting may temporarily retain redacted samples only with explicit user opt-in.

## 14. Error Handling

- Parser uncertainty -> pending confirmation instead of silent posting.
- Unknown merchant -> use existing category rules, otherwise Other and optionally ask user later.
- Unknown funding account -> pending confirmation or configured channel default.
- Notification permission revoked -> surface listener-health warning.
- Duplicate candidate -> suppress and record diagnostic reason locally.
- Database migration failure -> rollback and continue using untouched original JSON until repaired.
- AI provider failure -> core bookkeeping remains fully functional.

## 15. Testing Strategy

### Dart tests

- account balance calculations;
- transaction edit/delete reversibility;
- transfer accounting;
- budget aggregation;
- merchant-rule matching;
- deduplication logic;
- JSON -> SQLite migration;
- AI privacy payload sanitization.

### Kotlin tests

- notification text normalization;
- parser fixtures for WeChat, Alipay, UnionPay and bank examples;
- package allowlist behavior;
- confidence scoring;
- source fingerprint generation.

### Integration tests

- native parsed event -> Flutter pending capture;
- confirmed capture -> transaction -> account balance -> budget update;
- duplicate notifications do not double-post;
- migration preserves totals.

## 16. Delivery Phases

### Phase 1 — Data foundation

- introduce SQLite repository;
- migrate existing JSON data;
- formalize account/transaction/merchant-rule models;
- derive balances from ledger history;
- add migration and accounting tests.

### Phase 2 — Android automatic capture

- Kotlin notification listener;
- parser framework and source allowlist;
- Flutter native bridge;
- pending confirmation flow;
- deduplication and account matching.

### Phase 3 — Product integration

- asset page improvements;
- monthly bill filters;
- channel/account distinction in UI;
- automatic-capture settings and listener health;
- merchant learning UI.

### Phase 4 — AI analysis

- local analytics snapshot service;
- privacy-mode selector;
- provider abstraction;
- secure API-key storage;
- monthly AI report and chat-style analysis.

### Phase 5 — Backup and hardening

- database export/import;
- encrypted backup option;
- parser diagnostics;
- broader payment notification fixtures;
- release build and migration regression testing.

## 17. Definition of Done for V2 Core

V2 Core is complete when a user can:

1. maintain multiple wallets/cards/accounts;
2. see correct derived balances and total assets;
3. record expense/income/transfer manually;
4. view monthly bills, statistics and budgets;
5. enable Android notification access and receive parsed payment candidates;
6. automatically post high-confidence transactions without duplicates;
7. confirm ambiguous transactions before balances change;
8. teach merchant/category/account rules through corrections;
9. migrate existing `data.json` without losing totals;
10. optionally request AI analysis under explicit privacy settings while the core app remains fully functional offline.
