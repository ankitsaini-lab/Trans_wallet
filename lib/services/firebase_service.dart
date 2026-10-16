import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:transwallet/firebase_options.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/network_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  developer.log(
    "Handling background notification: ${message.messageId}",
    name: 'FirebaseService',
  );
}

class FirebaseService extends GetxService {
  static FirebaseService get to => Get.find<FirebaseService>();

  final RxString fcmToken = ''.obs;
  final GetStorage _storage = GetStorage();

  bool _isFetchingToken = false;
  Timer? _retryTimer;
  Worker? _networkWorker;

  FlutterLocalNotificationsPlugin? _localNotifications;
  bool _isLocalNotificationsInitialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important push notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<FirebaseService> init() async {
    try {
      debugPrint("🔥 [Firebase] Initializing Firebase Core...");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("✅ [Firebase] Firebase Core initialized successfully.");

      // Restore cached token immediately so app has it available offline
      final cachedToken = _storage.read<String>('fcm_token');
      if (cachedToken != null && cachedToken.isNotEmpty) {
        fcmToken.value = cachedToken;
        debugPrint("💾 [Firebase] Restored cached FCM token: $cachedToken");
      }

      // Request system notifications permission (Android 13+ & iOS)
      await _requestPermission();

      // Setup Local Notifications for heads-up display
      await _setupLocalNotifications();

      // Set iOS foreground presentation options
      try {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );
      } catch (e) {
        debugPrint("⚠️ [Firebase] Could not set iOS foreground options: $e");
      }

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Setup listeners
      _setupTokenRefreshListener();
      _setupForegroundListeners();
      _setupNetworkReconnectionListener();

      // Fetch initial FCM token in background
      unawaited(_getToken());
    } catch (e, stackTrace) {
      debugPrint("❌ [Firebase] Initialization failed: $e");
      developer.log(
        "Firebase init error",
        error: e,
        stackTrace: stackTrace,
        name: 'FirebaseService',
      );
    }
    return this;
  }

  Future<void> _setupLocalNotifications() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings('ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      final success = await plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint("🔔 [Notification Clicked]: ${response.payload}");
        },
      );

      _localNotifications = plugin;
      _isLocalNotificationsInitialized = success ?? true;

      final androidImplementation = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(_channel);
      }

      debugPrint("✅ [Firebase] Local Notifications initialized successfully.");
    } on MissingPluginException catch (e) {
      _isLocalNotificationsInitialized = false;
      debugPrint(
        "⚠️ [Firebase] MissingPluginException for local_notifications: $e\n"
        "💡 NOTE: Please stop and rebuild/re-run the app fully (`flutter run`) so native Gradle/iOS bindings are compiled.",
      );
    } catch (e) {
      _isLocalNotificationsInitialized = false;
      debugPrint("⚠️ [Firebase] Failed to initialize local notifications: $e");
    }
  }

  Future<void> _requestPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        '🔔 [Firebase] FCM Notification Permission status: ${settings.authorizationStatus}',
      );

      // Explicitly check Android 13+ / OS level Notification permission
      final status = await Permission.notification.status;
      if (status.isDenied) {
        final requestedStatus = await Permission.notification.request();
        debugPrint(
          '🔔 [System OS] Notification permission requested: $requestedStatus',
        );
      } else if (status.isPermanentlyDenied) {
        debugPrint(
          '⚠️ [System OS] Notification permission is PERMANENTLY DENIED in OS Settings.',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [Firebase] Failed to request notification permission: $e');
    }
  }

  /// Public method to check if notifications are disabled on the mobile device
  /// and prompt the user to open settings if disabled.
  Future<bool> checkAndPromptNotificationPermission({
    bool showDialogIfDisabled = true,
  }) async {
    try {
      final status = await Permission.notification.status;
      debugPrint('🔔 [Firebase] Notification status check: $status');

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final requested = await Permission.notification.request();
        if (requested.isGranted) {
          return true;
        }
      }

      if (showDialogIfDisabled) {
        showEnableNotificationsDialog();
      }
    } catch (e) {
      debugPrint("⚠️ Error checking notification status: $e");
    }
    return false;
  }

  /// Displays a modern dialog asking the user to open Mobile App Settings to turn on notifications
  void showEnableNotificationsDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.notifications_off_rounded, color: Color(0xFFFFD500)),
            SizedBox(width: 10),
            Text(
              "Notifications Disabled",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: const Text(
          "Push notifications are currently turned off for Transwallet in your mobile settings.\n\n"
          "To receive real-time payment alerts, security updates, and transaction receipts, please enable notifications in App Settings.",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Not Now", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD500),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              Get.back();
              await openAppSettings();
            },
            child: const Text(
              "Open Settings",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _registerTokenWithBackend(String token) async {
    if (!Get.isRegistered<ApiService>()) {
      debugPrint(
        "⚠️ [Firebase ➔ Backend] ApiService is not registered yet. Skipping token sync.",
      );
      return;
    }

    try {
      final platform = GetPlatform.isIOS ? 'ios' : 'android';
      debugPrint("==================================================");
      debugPrint("🚀 [Firebase ➔ Backend] Registering FCM Device Token...");
      debugPrint("POST /api/v1/devices");
      debugPrint(
        "Payload: {\"platform\": \"$platform\", \"fcmToken\": \"$token\"}",
      );
      debugPrint("==================================================");

      final result = await ApiService.to.registerDeviceToken(token);

      debugPrint("==================================================");
      if (result != null &&
          (result['success'] == true || result['code'] == 'OK')) {
        debugPrint("✅ [Firebase ➔ Backend] FCM Token registered successfully!");
        debugPrint("Response Body: $result");
      } else {
        debugPrint(
          "⚠️ [Firebase ➔ Backend] Device token registration response: $result",
        );
      }
      debugPrint("==================================================");

      developer.log(
        "Backend /api/v1/devices response: $result",
        name: 'FirebaseService',
      );
    } catch (e, stackTrace) {
      debugPrint("❌ [Firebase ➔ Backend] Exception registering token: $e");
      developer.log(
        "Error registering device token with backend",
        error: e,
        stackTrace: stackTrace,
        name: 'FirebaseService',
      );
    }
  }

  void _setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      fcmToken.value = newToken;
      await _storage.write('fcm_token', newToken);

      debugPrint("==================================================");
      debugPrint("🔄 [Firebase] FCM Token refreshed!");
      debugPrint("NEW FCM TOKEN: $newToken");
      debugPrint("==================================================");

      developer.log("FCM Token refreshed: $newToken", name: 'FirebaseService');

      await _registerTokenWithBackend(newToken);
    });
  }

  void _setupNetworkReconnectionListener() {
    if (Get.isRegistered<NetworkService>()) {
      _networkWorker = ever<bool>(NetworkService.to.isConnected, (connected) {
        if (connected && fcmToken.value.isEmpty && !_isFetchingToken) {
          debugPrint("🌐 [Firebase] Network connection active -> Fetching FCM token...");
          fetchFcmToken();
        }
      });
    }
  }

  /// Fetches the FCM token with automatic retry and graceful offline handling.
  /// Does not crash or spam unhandled error logs on Google Play Services delays.
  Future<String?> fetchFcmToken({int maxRetries = 3}) async {
    if (_isFetchingToken) return fcmToken.value.isNotEmpty ? fcmToken.value : null;
    _isFetchingToken = true;

    try {
      int attempt = 0;
      while (attempt < maxRetries) {
        attempt++;
        try {
          debugPrint(
            "⏳ [Firebase] Requesting FCM Token (Attempt $attempt/$maxRetries)...",
          );
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null && token.isNotEmpty) {
            fcmToken.value = token;
            await _storage.write('fcm_token', token);

            debugPrint("==================================================");
            debugPrint("🔥 [Firebase] FCM Token generated successfully!");
            debugPrint("FCM TOKEN: $token");
            debugPrint("==================================================");

            developer.log("FCM Token generated: $token", name: 'FirebaseService');

            _retryTimer?.cancel();
            await _registerTokenWithBackend(token);
            return token;
          } else {
            debugPrint("⚠️ [Firebase] FCM Token returned was null/empty.");
          }
        } catch (e) {
          final isRegistrationFailed = e.toString().contains("FCM Registration failed");
          if (isRegistrationFailed) {
            debugPrint(
              "ℹ️ [Firebase] Google Play Services FCM registration busy or awaiting network (Attempt $attempt/$maxRetries).",
            );
          } else {
            debugPrint("⚠️ [Firebase] Token attempt $attempt encountered: $e");
          }

          if (attempt < maxRetries) {
            final delayMs = 2000 * attempt;
            await Future.delayed(Duration(milliseconds: delayMs));
          }
        }
      }

      // If initial attempts could not complete (e.g. device network delayed or GMS warming up),
      // schedule an automatic background retry in 30 seconds rather than failing permanently
      debugPrint(
        "ℹ️ [Firebase] Initial token attempts deferred. Will auto-retry in 30s or on network reconnect.",
      );
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 30), () {
        if (fcmToken.value.isEmpty) {
          fetchFcmToken(maxRetries: 2);
        }
      });
    } finally {
      _isFetchingToken = false;
    }
    return fcmToken.value.isNotEmpty ? fcmToken.value : null;
  }

  @override
  void onClose() {
    _retryTimer?.cancel();
    _networkWorker?.dispose();
    super.onClose();
  }

  Future<void> _getToken() async {
    await fetchFcmToken();
  }

  void _setupForegroundListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '📩 [Firebase] Foreground Notification received: ${message.notification?.title} - ${message.notification?.body}',
      );

      final title = message.notification?.title ?? message.data['title'];
      final body = message.notification?.body ?? message.data['body'];

      if ((title != null || body != null) &&
          _isLocalNotificationsInitialized &&
          _localNotifications != null) {
        try {
          _localNotifications!.show(
            id: message.hashCode,
            title: title,
            body: body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: 'ic_launcher',
                largeIcon: const DrawableResourceAndroidBitmap('ic_launcher'),
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: message.data.toString(),
          );
        } catch (e) {
          debugPrint("⚠️ [Firebase] Error showing local notification: $e");
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '📱 [Firebase] App opened from background notification: ${message.data}',
      );
      developer.log(
        "onMessageOpenedApp: ${message.data}",
        name: 'FirebaseService',
      );
    });

    // Check initial message if app launched from terminated state via notification tap
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        debugPrint(
          '🚀 [Firebase] App launched from terminated state via notification: ${message.data}',
        );
        developer.log(
          "getInitialMessage (Terminated State): ${message.data}",
          name: 'FirebaseService',
        );
      }
    });
  }
}
