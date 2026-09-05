# Smart Bookkeeping V2 Phase 2 Android Auto Capture Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Use TDD for parser/dedup/account-matching behavior.

**Goal:** Capture supported Android payment notifications, parse them locally into structured candidates, bridge them to Flutter, deduplicate them, and either auto-post high-confidence transactions or place uncertain ones into a pending-confirmation queue.

**Architecture:** Kotlin owns `NotificationListenerService`, package allowlisting, visible notification field extraction and parser rules. Flutter owns pending-capture persistence, account matching, merchant rules, deduplication and final transaction posting into SQLite.

**Spec:** `docs/superpowers/specs/2026-09-05-smart-bookkeeping-v2-design.md`

## Constraints

- No Root, Xposed, accessibility automation, traffic interception or payment-app private database access.
- Raw notification text is not persisted by default.
- Package allowlist must reject unrelated app notifications.
- Low-confidence candidates never modify balances automatically.
- Payment channel and funding account remain separate concepts.

---

### Task 1: Kotlin parser domain and fixtures

**Files:**
- Create: `android/app/src/main/kotlin/com/example/jizhang/capture/PaymentCandidate.kt`
- Create: `android/app/src/main/kotlin/com/example/jizhang/capture/PaymentChannel.kt`
- Create: `android/app/src/main/kotlin/com/example/jizhang/capture/PaymentDirection.kt`
- Create: `android/app/src/main/kotlin/com/example/jizhang/capture/NotificationTextNormalizer.kt`
- Create: `android/app/src/main/kotlin/com/example/jizhang/capture/PaymentNotificationParser.kt`
- Create: `android/app/src/test/kotlin/com/example/jizhang/capture/PaymentNotificationParserTest.kt`

**Deliverable:** Pure Kotlin parser tests for WeChat, Alipay, UnionPay and bank notification examples.

### Task 2: Source allowlist and fingerprinting

**Files:**
- Create: `android/app/src/main/kotlin/com/example/jizhang/capture/PaymentSourceRegistry.kt`
- Create: `android/app/src/main/kotlin/com/example/jizhang/capture/SourceFingerprint.kt`
- Create: `android/app/src/test/kotlin/com/example/jizhang/capture/PaymentSourceRegistryTest.kt`
- Create: `android/app/src/test/kotlin/com/example/jizhang/capture/SourceFingerprintTest.kt`

**Deliverable:** Known package IDs only; deterministic fingerprint from normalized source/package/channel/direction/amount/merchant/time bucket.

### Task 3: NotificationListenerService

**Files:**
- Create: `android/app/src/main/kotlin/com/example/jizhang/capture/PaymentNotificationListenerService.kt`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Deliverable:** Listener extracts `EXTRA_TITLE`, `EXTRA_TEXT`, `EXTRA_SUB_TEXT` and grouped-child notification fields, parses only allowlisted packages, and forwards structured candidates without persisting raw notification text.

### Task 4: Flutter native bridge

**Files:**
- Modify: `android/app/src/main/kotlin/com/example/jizhang/MainActivity.kt`
- Create: `lib/services/auto_capture/native_capture_bridge.dart`
- Create: `lib/models/pending_capture.dart`
- Test: `test/services/auto_capture/native_capture_bridge_test.dart`

**Deliverable:** EventChannel/MethodChannel contract for candidate stream, listener permission status and opening Android notification-access settings.

### Task 5: Pending capture repository

**Files:**
- Create: `lib/database/v2/pending_capture_repository.dart`
- Test: `test/database/v2/pending_capture_repository_test.dart`

**Deliverable:** Insert-once by source fingerprint, pending/confirmed/ignored states, unresolved captures do not alter balances.

### Task 6: Deduplication and account matching

**Files:**
- Create: `lib/services/auto_capture/capture_deduplicator.dart`
- Create: `lib/services/auto_capture/account_matcher.dart`
- Test: `test/services/auto_capture/capture_deduplicator_test.dart`
- Test: `test/services/auto_capture/account_matcher_test.dart`

**Deliverable:** Same-notification and cross-channel duplicate suppression; matching order explicit identifier -> user rule -> channel default -> unresolved.

### Task 7: Merchant rule learning

**Files:**
- Create: `lib/services/merchant_rule_matcher.dart`
- Extend: `lib/database/v2/merchant_rule_repository.dart`
- Test: `test/services/merchant_rule_matcher_test.dart`

**Deliverable:** User corrections can create/update local merchant rules and future captures reuse them without AI.

### Task 8: Posting policy

**Files:**
- Create: `lib/services/auto_capture/capture_posting_service.dart`
- Test: `test/services/auto_capture/capture_posting_service_test.dart`

**Deliverable:** High-confidence + resolved account + non-duplicate candidate can post automatically when enabled; otherwise pending confirmation.

### Task 9: Capture settings and listener health UI

**Files:**
- Create: `lib/screens/auto_capture_settings_screen.dart`
- Modify: relevant settings/navigation files

**Deliverable:** Notification access status, enable/disable auto-post, default accounts by channel, pending count, test-listener diagnostics and privacy explanation.
