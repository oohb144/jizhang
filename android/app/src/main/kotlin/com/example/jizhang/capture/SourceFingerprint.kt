package com.example.jizhang.capture

import java.security.MessageDigest
import java.util.Locale

object SourceFingerprint {
    fun create(
        packageName: String,
        channel: PaymentChannel,
        direction: PaymentDirection,
        amount: Double,
        merchant: String?,
        receivedAtMillis: Long,
    ): String {
        val minuteBucket = receivedAtMillis / 60_000L
        val normalizedMerchant = NotificationTextNormalizer.normalize(merchant).lowercase()
        val canonical = listOf(
            packageName.trim().lowercase(),
            channel.name,
            direction.name,
            String.format(Locale.US, "%.2f", amount),
            normalizedMerchant,
            minuteBucket.toString(),
        ).joinToString("|")
        val digest = MessageDigest.getInstance("SHA-256").digest(canonical.toByteArray())
        return digest.joinToString("") { "%02x".format(it) }
    }
}
