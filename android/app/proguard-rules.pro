# ProGuard / R8 rules for PayU and Google Pay integration

# Ignore missing optional Google Pay / Paisa in-app API classes referenced by PayU SDK
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }

# PayU SDK rules
-dontwarn com.payu.**
-keep class com.payu.** { *; }

# Google Play Services & Wallet
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }

# Suppress missing class warnings from third-party libraries during R8 minification
-dontwarn **
