package com.trans.wallet

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telephony.SubscriptionInfo
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import com.google.android.gms.auth.api.identity.GetPhoneNumberHintIntentRequest
import com.google.android.gms.auth.api.identity.Identity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val SIM_CHANNEL = "com.trans.wallet/sim_service"
    private val REQ_PHONE_HINT = 10091
    private var pendingHintResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SIM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAvailableSimCards" -> {
                    try {
                        val simList = getActiveSimCards()
                        result.success(simList)
                    } catch (e: Exception) {
                        result.error("SIM_ERROR", e.message, null)
                    }
                }
                "requestPhoneNumberHint" -> {
                    requestPhoneNumberHint(result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestPhoneNumberHint(result: MethodChannel.Result) {
        try {
            val request = GetPhoneNumberHintIntentRequest.builder().build()
            Identity.getSignInClient(this)
                .getPhoneNumberHintIntent(request)
                .addOnSuccessListener { pendingIntent ->
                    try {
                        pendingHintResult = result
                        startIntentSenderForResult(
                            pendingIntent.intentSender,
                            REQ_PHONE_HINT,
                            null, 0, 0, 0, null
                        )
                    } catch (e: Exception) {
                        pendingHintResult = null
                        result.error("HINT_ERROR", e.message, null)
                    }
                }
                .addOnFailureListener { e ->
                    result.error("HINT_FAILED", e.message, null)
                }
        } catch (e: Exception) {
            result.error("HINT_EXCEPTION", e.message, null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_PHONE_HINT) {
            val res = pendingHintResult
            pendingHintResult = null
            if (resultCode == Activity.RESULT_OK && data != null) {
                try {
                    val rawNumber = Identity.getSignInClient(this).getPhoneNumberFromIntent(data)
                    var cleaned = rawNumber.replace(Regex("[^0-9]"), "")
                    if (cleaned.startsWith("91") && cleaned.length == 12) {
                        cleaned = cleaned.substring(2)
                    } else if (cleaned.length > 10) {
                        cleaned = cleaned.takeLast(10)
                    }
                    res?.success(cleaned)
                } catch (e: Exception) {
                    res?.error("PARSE_ERROR", e.message, null)
                }
            } else {
                res?.success("")
            }
        }
    }

    private fun getActiveSimCards(): List<Map<String, Any?>> {
        val list = mutableListOf<Map<String, Any?>>()
        val subscriptionManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as? SubscriptionManager
            ?: return list

        try {
            val activeList: List<SubscriptionInfo>? = subscriptionManager.activeSubscriptionInfoList
            if (activeList != null) {
                val tm = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager

                for (info in activeList) {
                    var number: String? = null

                    // 1. Try Android 13+ SubscriptionManager.getPhoneNumber
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            number = subscriptionManager.getPhoneNumber(info.subscriptionId)
                        }
                    } catch (_: Exception) {}

                    // 2. Try legacy SubscriptionInfo.number
                    if (number.isNullOrEmpty()) {
                        try {
                            @Suppress("DEPRECATION")
                            number = info.number
                        } catch (_: Exception) {}
                    }

                    // 3. Try TelephonyManager line1Number for specific subscription
                    if (number.isNullOrEmpty() && tm != null) {
                        try {
                            val subTm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                tm.createForSubscriptionId(info.subscriptionId)
                            } else {
                                tm
                            }
                            @Suppress("DEPRECATION")
                            number = subTm.line1Number
                        } catch (_: Exception) {}
                    }

                    // Clean formatted phone number (e.g. +91 98765 43210 -> 9876543210)
                    var cleanedNumber = ""
                    if (!number.isNullOrEmpty()) {
                        val digits = number.replace(Regex("[^0-9]"), "")
                        cleanedNumber = when {
                            digits.startsWith("91") && digits.length == 12 -> digits.substring(2)
                            digits.length > 10 -> digits.takeLast(10)
                            else -> digits
                        }
                    }

                    list.add(mapOf(
                        "slotIndex" to info.simSlotIndex,
                        "subscriptionId" to info.subscriptionId,
                        "carrierName" to (info.carrierName?.toString() ?: "SIM ${info.simSlotIndex + 1}"),
                        "displayName" to (info.displayName?.toString() ?: "SIM ${info.simSlotIndex + 1}"),
                        "countryIso" to (info.countryIso ?: "in"),
                        "number" to cleanedNumber
                    ))
                }
            }
        } catch (e: SecurityException) {
            // Permission not yet granted
        }
        return list
    }
}