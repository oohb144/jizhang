package com.example.jizhang.capture

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PaymentNotificationParserTest {
    private val parser = PaymentNotificationParser()

    @Test
    fun parsesWechatExpense() {
        val candidate = parser.parse(
            packageName = "com.tencent.mm",
            title = "微信支付",
            text = "微信支付凭证：已支付¥16.00",
            subText = null,
        )

        requireNotNull(candidate)
        assertEquals(16.0, candidate.amount, 0.001)
        assertEquals(PaymentDirection.EXPENSE, candidate.direction)
        assertEquals(PaymentChannel.WECHAT, candidate.channel)
        assertTrue(candidate.confidence >= 0.9)
    }

    @Test
    fun parsesAlipayExpense() {
        val candidate = parser.parse(
            packageName = "com.eg.android.AlipayGphone",
            title = "支付宝",
            text = "你有一笔 23.50 元的支出",
            subText = null,
        )

        requireNotNull(candidate)
        assertEquals(23.5, candidate.amount, 0.001)
        assertEquals(PaymentDirection.EXPENSE, candidate.direction)
        assertEquals(PaymentChannel.ALIPAY, candidate.channel)
    }

    @Test
    fun parsesBankExpenseAndMerchant() {
        val candidate = parser.parse(
            packageName = "com.icbc",
            title = "工商银行",
            text = "支出(消费支付宝-蜜雪冰城)6.00元",
            subText = null,
        )

        requireNotNull(candidate)
        assertEquals(6.0, candidate.amount, 0.001)
        assertEquals(PaymentDirection.EXPENSE, candidate.direction)
        assertEquals(PaymentChannel.BANK, candidate.channel)
        assertEquals("蜜雪冰城", candidate.merchant)
    }

    @Test
    fun ignoresMarketingTextWithoutPaymentConfirmation() {
        val candidate = parser.parse(
            packageName = "com.eg.android.AlipayGphone",
            title = "支付宝优惠",
            text = "满100减20，点击领取优惠券",
            subText = null,
        )

        assertNull(candidate)
    }

    @Test
    fun normalizerUnifiesCurrencyAndWhitespace() {
        assertEquals(
            "支付成功 ¥12.30",
            NotificationTextNormalizer.normalize("  支付成功   ￥12.30  "),
        )
    }
}
