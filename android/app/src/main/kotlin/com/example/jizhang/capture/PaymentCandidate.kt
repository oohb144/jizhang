package com.example.jizhang.capture

data class PaymentCandidate(
    val amount: Double,
    val direction: PaymentDirection,
    val channel: PaymentChannel,
    val merchant: String? = null,
    val confidence: Double,
    val sourcePackage: String,
)
