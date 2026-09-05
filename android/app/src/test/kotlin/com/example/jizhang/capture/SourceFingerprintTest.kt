package com.example.jizhang.capture

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

class SourceFingerprintTest {
    @Test
    fun sameCandidateInSameMinuteGetsSameFingerprint() {
        val a = SourceFingerprint.create(
            packageName = "com.tencent.mm",
            channel = PaymentChannel.WECHAT,
            direction = PaymentDirection.EXPENSE,
            amount = 12.30,
            merchant = "蜜雪冰城",
            receivedAtMillis = 1_788_600_010_000,
        )
        val b = SourceFingerprint.create(
            packageName = "com.tencent.mm",
            channel = PaymentChannel.WECHAT,
            direction = PaymentDirection.EXPENSE,
            amount = 12.30,
            merchant = " 蜜雪冰城 ",
            receivedAtMillis = 1_788_600_050_000,
        )
        assertEquals(a, b)
    }

    @Test
    fun differentAmountOrMinuteChangesFingerprint() {
        val base = SourceFingerprint.create(
            packageName = "com.tencent.mm",
            channel = PaymentChannel.WECHAT,
            direction = PaymentDirection.EXPENSE,
            amount = 12.30,
            merchant = "蜜雪冰城",
            receivedAtMillis = 1_788_600_010_000,
        )
        val differentAmount = SourceFingerprint.create(
            packageName = "com.tencent.mm",
            channel = PaymentChannel.WECHAT,
            direction = PaymentDirection.EXPENSE,
            amount = 13.30,
            merchant = "蜜雪冰城",
            receivedAtMillis = 1_788_600_010_000,
        )
        val differentMinute = SourceFingerprint.create(
            packageName = "com.tencent.mm",
            channel = PaymentChannel.WECHAT,
            direction = PaymentDirection.EXPENSE,
            amount = 12.30,
            merchant = "蜜雪冰城",
            receivedAtMillis = 1_788_600_090_000,
        )
        assertNotEquals(base, differentAmount)
        assertNotEquals(base, differentMinute)
    }
}
