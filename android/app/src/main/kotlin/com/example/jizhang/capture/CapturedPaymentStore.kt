package com.example.jizhang.capture

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object CapturedPaymentStore {
    private const val PREFS = "jizhang_auto_capture"
    private const val KEY_QUEUE = "candidate_queue"
    private const val KEY_RECENT = "recent_fingerprints"
    private const val MAX_QUEUE = 200
    private const val RECENT_TTL_MS = 10 * 60 * 1000L

    @Synchronized
    fun enqueue(context: Context, candidate: PaymentCandidate, receivedAtMillis: Long, fingerprint: String) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val recent = readObject(prefs.getString(KEY_RECENT, null))
        purgeOld(recent, receivedAtMillis)
        if (recent.has(fingerprint)) return

        val array = readArray(prefs.getString(KEY_QUEUE, null))
        val item = JSONObject().apply {
            put("amount", candidate.amount)
            put("direction", candidate.direction.name.lowercase())
            put("channel", candidate.channel.name.lowercase())
            put("merchant", candidate.merchant ?: JSONObject.NULL)
            put("confidence", candidate.confidence)
            put("sourcePackage", candidate.sourcePackage)
            put("sourceFingerprint", fingerprint)
            put("receivedAt", receivedAtMillis)
        }
        array.put(item)
        while (array.length() > MAX_QUEUE) array.remove(0)
        recent.put(fingerprint, receivedAtMillis)

        prefs.edit()
            .putString(KEY_QUEUE, array.toString())
            .putString(KEY_RECENT, recent.toString())
            .apply()
    }

    @Synchronized
    fun drain(context: Context): List<Map<String, Any?>> {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val array = readArray(prefs.getString(KEY_QUEUE, null))
        val result = mutableListOf<Map<String, Any?>>()
        for (index in 0 until array.length()) {
            val item = array.optJSONObject(index) ?: continue
            result += mapOf(
                "amount" to item.optDouble("amount"),
                "direction" to item.optString("direction"),
                "channel" to item.optString("channel"),
                "merchant" to if (item.isNull("merchant")) null else item.optString("merchant"),
                "confidence" to item.optDouble("confidence"),
                "sourcePackage" to item.optString("sourcePackage"),
                "sourceFingerprint" to item.optString("sourceFingerprint"),
                "receivedAt" to item.optLong("receivedAt"),
            )
        }
        prefs.edit().remove(KEY_QUEUE).apply()
        return result
    }

    private fun purgeOld(objectValue: JSONObject, now: Long) {
        val keys = objectValue.keys().asSequence().toList()
        for (key in keys) {
            val timestamp = objectValue.optLong(key, 0L)
            if (timestamp <= 0 || now - timestamp > RECENT_TTL_MS) objectValue.remove(key)
        }
    }

    private fun readArray(value: String?): JSONArray = try {
        if (value.isNullOrBlank()) JSONArray() else JSONArray(value)
    } catch (_: Exception) {
        JSONArray()
    }

    private fun readObject(value: String?): JSONObject = try {
        if (value.isNullOrBlank()) JSONObject() else JSONObject(value)
    } catch (_: Exception) {
        JSONObject()
    }
}
