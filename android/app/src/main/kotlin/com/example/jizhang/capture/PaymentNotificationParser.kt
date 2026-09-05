package com.example.jizhang.capture

class PaymentNotificationParser {
    private val wechatExpense = Regex("已支付\\s*¥?\\s*(\\d+(?:\\.\\d{1,2})?)")
    private val alipayExpense = Regex("(\\d+(?:\\.\\d{1,2})?)\\s*元的支出")
    private val bankExpense = Regex("支出.*?(\\d+(?:\\.\\d{1,2})?)\\s*元")
    private val bankMerchant = Regex("支付宝-([^）)]+)[）)]")

    fun parse(
        packageName: String,
        title: String?,
        text: String?,
        subText: String?,
    ): PaymentCandidate? {
        val normalizedTitle = NotificationTextNormalizer.normalize(title)
        val normalizedText = NotificationTextNormalizer.normalize(text)
        val normalizedSubText = NotificationTextNormalizer.normalize(subText)
        val combined = listOf(normalizedTitle, normalizedText, normalizedSubText)
            .filter { it.isNotEmpty() }
            .joinToString(" ")

        if (combined.isEmpty()) return null

        return when (packageName) {
            "com.tencent.mm" -> parseWechat(packageName, combined)
            "com.eg.android.AlipayGphone" -> parseAlipay(packageName, combined)
            else -> parseBank(packageName, combined)
        }
    }

    private fun parseWechat(packageName: String, text: String): PaymentCandidate? {
        val match = wechatExpense.find(text) ?: return null
        return PaymentCandidate(
            amount = match.groupValues[1].toDouble(),
            direction = PaymentDirection.EXPENSE,
            channel = PaymentChannel.WECHAT,
            confidence = 0.96,
            sourcePackage = packageName,
        )
    }

    private fun parseAlipay(packageName: String, text: String): PaymentCandidate? {
        val match = alipayExpense.find(text) ?: return null
        return PaymentCandidate(
            amount = match.groupValues[1].toDouble(),
            direction = PaymentDirection.EXPENSE,
            channel = PaymentChannel.ALIPAY,
            confidence = 0.96,
            sourcePackage = packageName,
        )
    }

    private fun parseBank(packageName: String, text: String): PaymentCandidate? {
        if (!looksLikeBankNotification(packageName, text)) return null
        val match = bankExpense.find(text) ?: return null
        val merchant = bankMerchant.find(text)?.groupValues?.getOrNull(1)?.trim()
        return PaymentCandidate(
            amount = match.groupValues[1].toDouble(),
            direction = PaymentDirection.EXPENSE,
            channel = PaymentChannel.BANK,
            merchant = merchant,
            confidence = 0.90,
            sourcePackage = packageName,
        )
    }

    private fun looksLikeBankNotification(packageName: String, text: String): Boolean {
        val packageHint = packageName.lowercase()
        if (packageHint.contains("bank") || packageHint.contains("icbc")) return true
        return listOf("工商银行", "农业银行", "中国银行", "建设银行", "招商银行")
            .any(text::contains)
    }
}
