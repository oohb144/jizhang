package com.example.jizhang.capture

object NotificationTextNormalizer {
    private val whitespace = Regex("\\s+")

    fun normalize(value: String?): String {
        if (value.isNullOrBlank()) return ""
        return value
            .replace('￥', '¥')
            .replace('\u3000', ' ')
            .replace(whitespace, " ")
            .trim()
    }
}
