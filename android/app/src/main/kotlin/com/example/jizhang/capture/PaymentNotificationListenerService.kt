package com.example.jizhang.capture

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class PaymentNotificationListenerService : NotificationListenerService() {
    private val parser = PaymentNotificationParser()

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val notification = sbn?.notification ?: return
        val packageName = sbn.packageName ?: return
        if (!PaymentSourceRegistry.isAllowed(packageName)) return

        val extras = notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()
        val candidate = parser.parse(
            packageName = packageName,
            title = title,
            text = text,
            subText = subText,
        ) ?: return

        val receivedAt = if (sbn.postTime > 0) sbn.postTime else System.currentTimeMillis()
        val fingerprint = SourceFingerprint.create(
            packageName = packageName,
            channel = candidate.channel,
            direction = candidate.direction,
            amount = candidate.amount,
            merchant = candidate.merchant,
            receivedAtMillis = receivedAt,
        )
        CapturedPaymentStore.enqueue(this, candidate, receivedAt, fingerprint)
    }
}
