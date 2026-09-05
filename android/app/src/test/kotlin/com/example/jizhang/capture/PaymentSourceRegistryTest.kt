package com.example.jizhang.capture

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PaymentSourceRegistryTest {
    @Test
    fun acceptsKnownPaymentApps() {
        assertTrue(PaymentSourceRegistry.isAllowed("com.tencent.mm"))
        assertTrue(PaymentSourceRegistry.isAllowed("com.eg.android.AlipayGphone"))
        assertTrue(PaymentSourceRegistry.isAllowed("com.unionpay"))
        assertTrue(PaymentSourceRegistry.isAllowed("com.icbc"))
    }

    @Test
    fun rejectsUnrelatedApps() {
        assertFalse(PaymentSourceRegistry.isAllowed("com.example.shopping"))
        assertFalse(PaymentSourceRegistry.isAllowed("com.android.systemui"))
    }
}
