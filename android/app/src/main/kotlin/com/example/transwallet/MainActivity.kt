package com.trans.wallet

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.trans.wallet/sms_user_consent"
    private val smsConsentRequestCode = 1002

    private var smsReceiver: BroadcastReceiver? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startListening" -> {
                        val senderPhoneNumber = call.argument<String>("senderPhoneNumber")
                        startSmsUserConsent(senderPhoneNumber, result)
                    }
                    "stopListening" -> {
                        stopListening(result)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun startSmsUserConsent(senderPhoneNumber: String?, result: MethodChannel.Result) {
        unregisterReceiverSafely()

        // Safely notify any prior pending result that a new request took over
        pendingResult?.success(mapOf("status" to "superseded"))
        pendingResult = result

        val client = SmsRetriever.getClient(this)
        val task = client.startSmsUserConsent(senderPhoneNumber)

        task.addOnSuccessListener {
            registerSmsReceiver()
        }

        task.addOnFailureListener { e ->
            unregisterReceiverSafely()
            pendingResult?.error("START_FAILED", e.localizedMessage, null)
            pendingResult = null
        }
    }

    private fun registerSmsReceiver() {
        val intentFilter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)

        smsReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == SmsRetriever.SMS_RETRIEVED_ACTION) {
                    val extras = intent.extras ?: return
                    val status = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        extras.getParcelable(SmsRetriever.EXTRA_STATUS, Status::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        extras.getParcelable(SmsRetriever.EXTRA_STATUS)
                    } ?: return

                    when (status.statusCode) {
                        CommonStatusCodes.SUCCESS -> {
                            val consentIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                extras.getParcelable(SmsRetriever.EXTRA_CONSENT_INTENT, Intent::class.java)
                            } else {
                                @Suppress("DEPRECATION")
                                extras.getParcelable(SmsRetriever.EXTRA_CONSENT_INTENT)
                            }

                            if (consentIntent != null) {
                                try {
                                    startActivityForResult(consentIntent, smsConsentRequestCode)
                                } catch (e: ActivityNotFoundException) {
                                    unregisterReceiverSafely()
                                    pendingResult?.error("ACTIVITY_NOT_FOUND", e.localizedMessage, null)
                                    pendingResult = null
                                }
                            } else {
                                unregisterReceiverSafely()
                                pendingResult?.error("NO_CONSENT_INTENT", "Consent intent was null", null)
                                pendingResult = null
                            }
                        }
                        CommonStatusCodes.TIMEOUT -> {
                            unregisterReceiverSafely()
                            pendingResult?.success(mapOf("status" to "timeout"))
                            pendingResult = null
                        }
                    }
                }
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            registerReceiver(
                smsReceiver,
                intentFilter,
                SmsRetriever.SEND_PERMISSION,
                null,
                RECEIVER_EXPORTED
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            registerReceiver(
                smsReceiver,
                intentFilter,
                SmsRetriever.SEND_PERMISSION,
                null
            )
        } else {
            registerReceiver(smsReceiver, intentFilter)
        }
    }

    private fun stopListening(result: MethodChannel.Result?) {
        unregisterReceiverSafely()
        pendingResult?.success(mapOf("status" to "stopped"))
        pendingResult = null
        result?.success(true)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == smsConsentRequestCode) {
            unregisterReceiverSafely()

            when (resultCode) {
                Activity.RESULT_OK -> {
                    val message = data?.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE)
                    val regex = Regex("\\b\\d{6}\\b")
                    val code = message?.let { regex.find(it)?.value }

                    pendingResult?.success(
                        mapOf(
                            "status" to "success",
                            "sms" to message,
                            "code" to code
                        )
                    )
                }
                Activity.RESULT_CANCELED -> {
                    pendingResult?.success(mapOf("status" to "denied"))
                }
                else -> {
                    pendingResult?.success(mapOf("status" to "cancelled"))
                }
            }
            pendingResult = null
        }
    }

    private fun unregisterReceiverSafely() {
        if (smsReceiver != null) {
            try {
                unregisterReceiver(smsReceiver)
            } catch (_: Exception) {
            }
            smsReceiver = null
        }
    }

    override fun onDestroy() {
        unregisterReceiverSafely()
        pendingResult = null
        super.onDestroy()
    }
}