package com.example.jizhang.capture

object PaymentSourceRegistry {
    private val exactPackages = setOf(
        "com.tencent.mm",
        "com.eg.android.AlipayGphone",
        "com.unionpay",
        "com.icbc",
        "com.chinamworld.main",
        "com.chinamworld.bocmbci",
        "cmb.pb",
        "com.android.bankabc",
        "com.bankcomm.Bankcomm",
        "com.yitong.mbank.psbc",
    )

    fun isAllowed(packageName: String): Boolean = packageName in exactPackages
}
