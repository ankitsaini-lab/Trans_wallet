import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/services/network_service.dart';

/// Wraps the entire application and displays a full-screen "No Internet Connection" overlay
/// whenever [NetworkService.to.isConnected] is false, blocking all user actions until restored.
class NoInternetOverlay extends StatelessWidget {
  final Widget child;

  const NoInternetOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NetworkService>()) {
      return child;
    }

    final networkService = NetworkService.to;

    return Stack(
      children: [
        child,
        Obx(() {
          if (networkService.isConnected.value) {
            return const SizedBox.shrink();
          }

          return Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: const _NoInternetScreenView(),
            ),
          );
        }),
      ],
    );
  }
}

class _NoInternetScreenView extends StatelessWidget {
  const _NoInternetScreenView();

  @override
  Widget build(BuildContext context) {
    final networkService = NetworkService.to;

    return Stack(
      children: [
        // 1. High-Security Backdrop Filter blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFF7F7).withValues(alpha: 0.98),
                    const Color(0xFFFEF2F1).withValues(alpha: 0.99),
                    const Color(0xFFFFF1F1).withValues(alpha: 0.98),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),

        // 2. No Internet Message & Actions
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Wifi Off Icon Container
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: primaryRed.withValues(alpha: 0.35),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryRed.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.wifi_off_rounded,
                      color: primaryRed,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  "No Internet Connection",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Description
                const Text(
                  "Please check your Wi-Fi or mobile data connection and try again to continue using Transwallet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryText,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(flex: 2),

                // Retry Connection Button
                Obx(() {
                  final isChecking = networkService.isChecking.value;

                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        isChecking ? "Checking Connection..." : "Retry Connection",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: isChecking
                          ? null
                          : () async {
                              final connected =
                                  await networkService.checkConnectivity();
                              if (!connected) {
                                Get.snackbar(
                                  "Still Offline",
                                  "Internet connection is still unavailable. Please check your network settings.",
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.black87,
                                  colorText: Colors.white,
                                  margin: const EdgeInsets.all(16),
                                );
                              }
                            },
                    ),
                  );
                }),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
