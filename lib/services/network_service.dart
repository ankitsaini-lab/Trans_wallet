import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Centralized service that monitors internet connectivity in real time.
/// Uses OS level connection changes (Connectivity) + active socket/HTTP pinging.
/// When internet connection is lost, [isConnected] becomes false,
/// showing the NoInternetOverlay screen.
class NetworkService extends GetxService with WidgetsBindingObserver {
  static NetworkService get to => Get.find<NetworkService>();

  final RxBool isConnected = true.obs;
  final RxBool isChecking = false.obs;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicTimer;

  Future<NetworkService> init() async {
    WidgetsBinding.instance.addObserver(this);

    // 1. Listen to real-time OS network state changes if plugin is available
    try {
      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen((results) {
        developer.log('[NetworkService] OS Connectivity Changed: $results');
        if (results.isEmpty ||
            results.every((r) => r == ConnectivityResult.none)) {
          isConnected.value = false;
        }
        checkConnectivity();
      }, onError: (err) {
        developer.log('[NetworkService] Connectivity stream error: $err');
      });
    } catch (e) {
      developer.log(
        '[NetworkService] Could not register connectivity listener: $e',
      );
    }

    // Initial check
    await checkConnectivity();

    // 2. Backup periodic check every 3 seconds
    _periodicTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => checkConnectivity(),
    );

    return this;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkConnectivity();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _periodicTimer?.cancel();
    super.onClose();
  }

  /// Performs hardware check + active connection test (concurrent DNS, Socket & HTTP pings)
  Future<bool> checkConnectivity() async {
    if (isChecking.value) return isConnected.value;

    try {
      isChecking.value = true;

      // 1. Hardware interface check (guarded against MissingPluginException)
      try {
        final connectivityResults = await _connectivity
            .checkConnectivity()
            .timeout(const Duration(milliseconds: 800));
        if (connectivityResults.isEmpty ||
            connectivityResults.every((r) => r == ConnectivityResult.none)) {
          if (isConnected.value) {
            developer.log(
              '[NetworkService] Hardware interface disconnected (No Wi-Fi/Cellular).',
            );
          }
          isConnected.value = false;
          isChecking.value = false;
          return false;
        }
      } on MissingPluginException {
        // Fallback to active pings when native plugin channel is not registered
      } catch (_) {}

      // 2. Perform fast concurrent network pings (DNS, Socket, HTTP in parallel)
      final hasNet = await _performFastConcurrentPing();

      if (hasNet) {
        if (!isConnected.value) {
          developer.log('[NetworkService] Internet connection RESTORED.');
        }
        isConnected.value = true;
        isChecking.value = false;
        return true;
      }
    } catch (e) {
      developer.log('[NetworkService] Error checking connectivity: $e');
    }

    if (isConnected.value) {
      developer.log('[NetworkService] Internet connection LOST.');
    }
    isConnected.value = false;
    isChecking.value = false;
    return false;
  }

  /// Runs DNS lookup, TCP socket test, and HTTP 204 ping in parallel (1.2s max)
  Future<bool> _performFastConcurrentPing() async {
    final results = await Future.wait([
      _pingDns(),
      _pingSocket(),
      _pingHttp(),
    ]);

    return results.any((success) => success == true);
  }

  Future<bool> _pingDns() async {
    try {
      final res = await InternetAddress.lookup('google.com')
          .timeout(const Duration(milliseconds: 1200));
      return res.isNotEmpty && res[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _pingSocket() async {
    try {
      final socket = await Socket.connect(
        '1.1.1.1',
        53,
        timeout: const Duration(milliseconds: 1200),
      );
      socket.destroy();
      return true;
    } catch (_) {
      try {
        final socket2 = await Socket.connect(
          '8.8.8.8',
          53,
          timeout: const Duration(milliseconds: 1200),
        );
        socket2.destroy();
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<bool> _pingHttp() async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(milliseconds: 1200);
      final request = await client.getUrl(
        Uri.parse('https://www.google.com/generate_204'),
      );
      final response = await request.close();
      client.close();
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
