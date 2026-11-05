import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/widgets/constsize.dart';

/// Top floating banner that slides down smoothly when the backend server
/// is unreachable, in maintenance, or returning 5xx server-side errors.
class ServerStatusBanner extends StatelessWidget {
  final Widget child;

  const ServerStatusBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ApiService>()) {
      return child;
    }

    final api = ApiService.to;

    return Stack(
      children: [
        child,
        Obx(() {
          final isDown = api.isServerDown.value;
          final isDismissed = api.isBannerDismissed.value;

          return AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            top: (isDown && !isDismissed) ? 0 : -140,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryYellow.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => ServerErrorSheet.show(),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryYellow.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_off_rounded,
                              color: primaryYellow,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Flexible(
                                      child: Text(
                                        "Server Unavailable",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    if (api.lastServerErrorCode.value > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          "${api.lastServerErrorCode.value}",
                                          style: const TextStyle(
                                            color: primaryYellow,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  api.serverErrorMessage.value.isNotEmpty
                                      ? api.serverErrorMessage.value
                                      : "Experiencing server-side issues. Tap for details.",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Obx(() {
                            final isChecking =
                                api.isCheckingServerHealth.value;
                            return SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                onPressed: isChecking
                                    ? null
                                    : () => api.checkServerHealth(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryYellow,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: isChecking
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Text(
                                        "Retry",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            );
                          }),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white60,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              api.isBannerDismissed.value = true;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Comprehensive, reassuring modal bottom sheet for server outages and maintenance
class ServerErrorSheet extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;
  final int? statusCode;

  const ServerErrorSheet({
    super.key,
    this.onRetry,
    this.customMessage,
    this.statusCode,
  });

  static void show({
    VoidCallback? onRetry,
    String? customMessage,
    int? statusCode,
  }) {
    if (Get.isBottomSheetOpen == true) return;

    Get.bottomSheet(
      ServerErrorSheet(
        onRetry: onRetry,
        customMessage: customMessage,
        statusCode: statusCode,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = Get.isRegistered<ApiService>() ? ApiService.to : null;
    final int code = statusCode ?? api?.lastServerErrorCode.value ?? 500;
    final bool isMaintenance = code == 503;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        context.responsive(24),
        context.responsive(14),
        context.responsive(24),
        context.responsive(28),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: context.responsive(40),
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: context.responsive(22)),

            // Icon with soft glow
            Container(
              width: context.responsive(76),
              height: context.responsive(76),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMaintenance
                    ? primaryLightYellow.withValues(alpha: 0.5)
                    : primaryRed.withValues(alpha: 0.12),
                border: Border.all(
                  color: isMaintenance
                      ? primaryYellow
                      : primaryRed.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  isMaintenance
                      ? Icons.build_circle_outlined
                      : Icons.cloud_off_rounded,
                  color: isMaintenance
                      ? const Color(0xFFB45309)
                      : primaryRed,
                  size: context.responsive(38),
                ),
              ),
            ),
            SizedBox(height: context.responsive(18)),

            // Title
            Text(
              isMaintenance
                  ? "Scheduled Maintenance"
                  : "Server Temporarily Unavailable",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.responsive(20),
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: context.responsive(8)),

            // Error badge
            if (code > 0)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(10),
                  vertical: context.responsive(3),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  code == 503
                      ? "Error 503 • Service Unavailable"
                      : code == 502
                          ? "Error 502 • Bad Gateway"
                          : code == 504
                              ? "Error 504 • Gateway Timeout"
                              : code == 500
                                  ? "Error 500 • Internal Server Error"
                                  : "Error Code: $code",
                  style: TextStyle(
                    fontSize: context.responsive(11),
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(height: context.responsive(14)),

            // Reassuring explanation
            Text(
              customMessage ??
                  (isMaintenance
                      ? "Our servers are currently undergoing scheduled maintenance to improve services. Your wallet funds and account data are safe."
                      : "We are currently experiencing technical difficulties connecting to our servers. Our engineering team is actively working on it."),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.responsive(13),
                color: Colors.grey.shade600,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: context.responsive(26)),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: context.responsive(14),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      "Close",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: context.responsive(14),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.responsive(12)),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (api != null) {
                        final ok = await api.checkServerHealth();
                        if (ok) {
                          Get.back();
                          if (onRetry != null) onRetry!();
                        }
                      } else if (onRetry != null) {
                        Get.back();
                        onRetry!();
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      "Retry",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.responsive(14),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryYellow,
                      foregroundColor: const Color(0xFF0F1013),
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        vertical: context.responsive(14),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// In-screen widget to replace empty lists or blank screens when the server fails
class ServerErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String? title;
  final String? message;
  final int? statusCode;

  const ServerErrorWidget({
    super.key,
    required this.onRetry,
    this.title,
    this.message,
    this.statusCode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.responsive(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.responsive(20)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryLightYellow.withValues(alpha: 0.45),
                border: Border.all(
                  color: primaryYellow.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                color: const Color(0xFFB45309),
                size: context.responsive(42),
              ),
            ),
            SizedBox(height: context.responsive(16)),
            Text(
              title ?? "Unable to Load Data",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.responsive(17),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: context.responsive(6)),
            Text(
              message ??
                  "The server could not be reached right now. Please tap below to try again.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.responsive(13),
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            SizedBox(height: context.responsive(20)),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryYellow,
                foregroundColor: const Color(0xFF0F1013),
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(24),
                  vertical: context.responsive(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
