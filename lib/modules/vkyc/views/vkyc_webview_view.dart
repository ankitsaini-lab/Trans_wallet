import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/modules/vkyc/controllers/vkyc_controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/constsize.dart';

class VkycWebviewView extends StatefulWidget {
  const VkycWebviewView({super.key});

  @override
  State<VkycWebviewView> createState() => _VkycWebviewViewState();
}

class _VkycWebviewViewState extends State<VkycWebviewView> {
  late final VkycController controller;
  InAppWebViewController? _webViewController;
  final RxBool isWebViewLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxBool isReviewInProgressDetected = false.obs;
  final RxBool isApprovedDetected = false.obs;
  final RxString detectedAppId = ''.obs;

  Timer? _safetyTimer;
  Timer? _domCheckTimer;
  String? passedUrl;
  bool isWebUrl = false;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<VkycController>()
        ? Get.find<VkycController>()
        : Get.put(VkycController());

    // Start external flow protection once — not on every rebuild
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.startExternalFlow(ExternalFlowType.vkyc);
    }

    passedUrl = Get.arguments is String ? Get.arguments as String : null;
    isWebUrl =
        passedUrl != null &&
        (passedUrl!.startsWith('http://') || passedUrl!.startsWith('https://'));

    // Safety timer to dismiss loader if webview takes too long
    _safetyTimer = Timer(const Duration(milliseconds: 500), () {
      isWebViewLoading.value = false;
    });

    _startDomInspector();
  }

  void _startDomInspector() {
    _domCheckTimer?.cancel();
    _domCheckTimer = Timer.periodic(const Duration(milliseconds: 1500), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _injectDomInspector();
    });
  }

  Future<void> _injectDomInspector() async {
    if (_webViewController == null) return;
    try {
      const script = '''
        (function() {
          try {
            const body = document.body;
            if (!body) return;
            const text = (body.innerText || '').toLowerCase();
            
            const isReview = text.includes('review in progress') ||
                             text.includes('under review') ||
                             text.includes('kyc has been submitted') ||
                             text.includes('application is under review') ||
                             text.includes('submitted for review');
                             
            const isApproved = text.includes('verification successful') ||
                               text.includes('kyc approved') ||
                               text.includes('vkyc approved') ||
                               text.includes('verification complete') ||
                               text.includes('verification completed') ||
                               text.includes('kyc completed') ||
                               text.includes('vkyc completed') ||
                               text.includes('successfully completed') ||
                               text.includes('call completed') ||
                               text.includes('session completed') ||
                               text.includes('video kyc completed') ||
                               text.includes('full kyc completed') ||
                               text.includes('congratulations');

            const isFailed = text.includes('verification failed') ||
                             text.includes('kyc rejected') ||
                             text.includes('verification unsuccessful') ||
                             text.includes('call disconnected');

            let appId = '';
            const match = (body.innerText || '').match(/application\\s*id[\\s\\S]*?#?([0-9a-zA-Z]+)/i);
            if (match && match[1]) {
              appId = match[1].trim();
            }

            if (isApproved) {
              if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                window.flutter_inappwebview.callHandler('vkycPageDetected', {
                  status: 'approved',
                  applicationId: appId
                });
              }

              // Hook any button containing 'continue', 'done', 'finish', 'close', 'ok'
              const buttons = document.querySelectorAll('button, a, div[role="button"], input[type="button"], input[type="submit"]');
              for (let i = 0; i < buttons.length; i++) {
                const btn = buttons[i];
                const bText = (btn.innerText || btn.value || '').trim().toLowerCase();
                if (bText === 'continue' || bText.includes('continue') || bText === 'done' || bText === 'finish' || bText === 'close' || bText === 'ok') {
                  if (!btn.__vkyc_hooked) {
                    btn.__vkyc_hooked = true;
                    btn.addEventListener('click', function(e) {
                      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                        window.flutter_inappwebview.callHandler('vkycAction', 'approved');
                      }
                    }, true);
                  }
                }
              }
            } else if (isReview) {
              if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                window.flutter_inappwebview.callHandler('vkycPageDetected', {
                  status: 'under_review',
                  applicationId: appId
                });
              }

              // Hook any button containing 'continue', 'done', 'finish', or 'close'
              const buttons = document.querySelectorAll('button, a, div[role="button"], input[type="button"], input[type="submit"]');
              for (let i = 0; i < buttons.length; i++) {
                const btn = buttons[i];
                const bText = (btn.innerText || btn.value || '').trim().toLowerCase();
                if (bText === 'continue' || bText.includes('continue') || bText === 'done' || bText === 'close') {
                  if (!btn.__vkyc_hooked) {
                    btn.__vkyc_hooked = true;
                    btn.addEventListener('click', function(e) {
                      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                        window.flutter_inappwebview.callHandler('vkycAction', 'under_review');
                      }
                    }, true);
                  }
                }
              }
            } else if (isFailed) {
              if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                window.flutter_inappwebview.callHandler('vkycPageDetected', {
                  status: 'rejected',
                  applicationId: appId
                });
              }
            }

            // Intercept window.close
            if (!window.__vkyc_close_patched) {
              window.__vkyc_close_patched = true;
              window.close = function() {
                if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                  window.flutter_inappwebview.callHandler('vkycWindowClose');
                }
              };
            }

            // Intercept M2P postMessage
            if (!window.__vkyc_msg_patched) {
              window.__vkyc_msg_patched = true;
              window.addEventListener('message', function(event) {
                try {
                  const data = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
                  const status = (data && (data.status || data.action || data.type || '')) + '';
                  if (status && window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                    window.flutter_inappwebview.callHandler('vkycAction', status.toLowerCase());
                  }
                } catch (_) {}
              });
            }
          } catch (e) {}
        })();
      ''';
      await _webViewController?.evaluateJavascript(source: script);
    } catch (_) {}
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _domCheckTimer?.cancel();
    try {
      _webViewController?.stopLoading();
    } catch (_) {}
    // Always release external flow guard when this screen is removed from the tree
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.finishExternalFlow(ExternalFlowType.vkyc);
    }
    super.dispose();
  }

  static const String vkycHtmlContent = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Video KYC Test Portal</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #0F0F1A;
      color: #FFFFFF;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 24px;
      text-align: center;
    }
    .card {
      background: #1E1E2E;
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 20px;
      padding: 32px 24px;
      max-width: 400px;
      width: 100%;
      box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
    }
    .badge {
      display: inline-block;
      background: rgba(255, 213, 0, 0.15);
      color: #FFD500;
      padding: 6px 14px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 700;
      letter-spacing: 1px;
      margin-bottom: 20px;
      text-transform: uppercase;
    }
    h1 { font-size: 22px; font-weight: 700; margin-bottom: 12px; }
    p { color: #9E9E9E; font-size: 14px; line-height: 1.5; margin-bottom: 28px; }
    .btn {
      display: block;
      width: 100%;
      padding: 16px;
      border-radius: 14px;
      font-size: 15px;
      font-weight: 700;
      text-decoration: none;
      border: none;
      cursor: pointer;
      margin-bottom: 12px;
      transition: opacity 0.2s;
    }
    .btn:active { opacity: 0.8; }
    .btn-primary { background: #E50914; color: #FFFFFF; }
    .btn-warning { background: #D97706; color: #FFFFFF; }
    .btn-secondary {
      background: rgba(255, 255, 255, 0.08);
      color: #B0B0B0;
      border: 1px solid rgba(255, 255, 255, 0.1);
    }
    .sim-info { font-size: 11px; color: #666; margin-top: 16px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">Simulated Provider</div>
    <h1>Video KYC Verification</h1>
    <p>This is a simulated VKYC provider page for testing full end-to-end redirection and deep-link completion.</p>
    
    <button class="btn btn-primary" onclick="triggerVkyc('success')">Complete VKYC (Approved)</button>
    <button class="btn btn-warning" onclick="triggerVkyc('under_review')">Submit for Review (Pending)</button>
    <button class="btn btn-secondary" onclick="triggerVkyc('cancel')">Cancel VKYC</button>

    <div class="sim-info">Transwallet VKYC Test Module</div>
  </div>

  <script>
    function triggerVkyc(status) {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('vkycAction', status);
      }
      window.location.href = 'transwallet://vkyc/' + status;
    }
  </script>
</body>
</html>
''';

  bool _handleVkycUrl(String urlString) {
    final lower = urlString.toLowerCase();

    final bool isCustomScheme =
        lower.startsWith("transwallet://") ||
        lower.startsWith("ppiapp://") ||
        lower.contains("/vkyc/") ||
        lower.contains("vkyc_callback") ||
        lower.contains("card-widget/return");

    if (!isCustomScheme &&
        !lower.contains("status=approved") &&
        !lower.contains("status=success") &&
        !lower.contains("status=completed") &&
        !lower.contains("status=under_review") &&
        !lower.contains("status=pending") &&
        !lower.contains("status=rejected")) {
      return false;
    }

    _safetyTimer?.cancel();
    _domCheckTimer?.cancel();

    // 1. Approved / Success
    if (lower.contains("success") ||
        lower.contains("approved") ||
        lower.contains("completed") ||
        lower.contains("vkyc/success") ||
        lower.contains("vkyc/approved")) {
      debugPrint("✅ [VKYC URL Intercepted -> SUCCESS]: $urlString");
      controller.onVkycSuccessDetected();
      return true;
    }

    // 2. Under Review / Review in Progress / Pending
    if (lower.contains("under_review") ||
        lower.contains("pending") ||
        lower.contains("in_progress") ||
        lower.contains("review")) {
      debugPrint("⏳ [VKYC URL Intercepted -> REVIEW]: $urlString");
      controller.onVkycReviewInProgressDetected();
      return true;
    }

    // 3. Rejected / Failed
    if (lower.contains("failed") || lower.contains("rejected")) {
      debugPrint("❌ [VKYC URL Intercepted -> REJECTED]: $urlString");
      controller.onVkycRejectedDetected();
      return true;
    }

    // 4. Cancelled / User Aborted
    if (lower.contains("cancel")) {
      debugPrint("🚫 [VKYC URL Intercepted -> CANCEL]: $urlString");
      controller.onVkycCancelDetected();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _safetyTimer?.cancel();
        _domCheckTimer?.cancel();
        if (isApprovedDetected.value) {
          controller.onVkycSuccessDetected();
          return;
        }
        if (isReviewInProgressDetected.value) {
          controller.onVkycReviewInProgressDetected(
            applicationId: detectedAppId.value,
          );
          return;
        }
        if (Get.isRegistered<AppLockService>()) {
          AppLockService.to.finishExternalFlow(ExternalFlowType.vkyc);
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leadingWidth: context.responsive(60),
          leading: AppBarBackButton(
            onTap: () {
              _safetyTimer?.cancel();
              _domCheckTimer?.cancel();
              if (isApprovedDetected.value) {
                controller.onVkycSuccessDetected();
                return;
              }
              if (isReviewInProgressDetected.value) {
                controller.onVkycReviewInProgressDetected(
                  applicationId: detectedAppId.value,
                );
                return;
              }
              if (Get.isRegistered<AppLockService>()) {
                AppLockService.to.finishExternalFlow(ExternalFlowType.vkyc);
              }
              Navigator.of(context).pop();
            },
          ),
          title: Obx(
            () => Text(
              isApprovedDetected.value
                  ? "KYC Approved"
                  : isReviewInProgressDetected.value
                  ? "Review in Progress"
                  : "Video KYC",
              style: TextStyle(
                color: Colors.black,
                fontSize: context.responsive(18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            Obx(() {
              if (isApprovedDetected.value) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TextButton.icon(
                    onPressed: () {
                      _safetyTimer?.cancel();
                      _domCheckTimer?.cancel();
                      controller.onVkycSuccessDetected();
                    },
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                    label: const Text(
                      "Done",
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              } else if (isReviewInProgressDetected.value) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TextButton.icon(
                    onPressed: () {
                      _safetyTimer?.cancel();
                      _domCheckTimer?.cancel();
                      controller.onVkycReviewInProgressDetected(
                        applicationId: detectedAppId.value,
                      );
                    },
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: primaryRed,
                      size: 18,
                    ),
                    label: const Text(
                      "Done",
                      style: TextStyle(
                        color: primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),

        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: isWebUrl
                  ? URLRequest(url: WebUri(passedUrl!))
                  : null,
              initialData: isWebUrl
                  ? null
                  : InAppWebViewInitialData(
                      data: vkycHtmlContent,
                      mimeType: 'text/html',
                      encoding: 'utf-8',
                      baseUrl: WebUri('about:blank'),
                    ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                javaScriptCanOpenWindowsAutomatically: true,
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                geolocationEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                transparentBackground: false,
                useWideViewPort: true,
                loadWithOverviewMode: true,
                supportZoom: false,
                clearCache: false,
              ),
              onPermissionRequest: (webViewController, request) async {
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
              onGeolocationPermissionsShowPrompt:
                  (webViewController, origin) async {
                    return GeolocationPermissionShowPromptResponse(
                      origin: origin,
                      allow: true,
                      retain: true,
                    );
                  },
              onCloseWindow: (webViewController) {
                debugPrint("🚪 [VKYC WebView onCloseWindow]");
                _safetyTimer?.cancel();
                _domCheckTimer?.cancel();
                if (isApprovedDetected.value) {
                  controller.onVkycSuccessDetected();
                } else if (isReviewInProgressDetected.value) {
                  controller.onVkycReviewInProgressDetected(
                    applicationId: detectedAppId.value,
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              onWebViewCreated: (webViewController) {
                _webViewController = webViewController;

                webViewController.addJavaScriptHandler(
                  handlerName: 'vkycAction',
                  callback: (args) {
                    final action = args.isNotEmpty
                        ? args.first.toString().toLowerCase()
                        : '';
                    debugPrint("⚡ [VKYC JS Bridge Action]: $action");
                    _safetyTimer?.cancel();
                    _domCheckTimer?.cancel();
                    if (action == 'success' ||
                        action == 'approved' ||
                        action == 'completed' ||
                        action == 'done' ||
                        action == 'finish' ||
                        action == 'ok') {
                      controller.onVkycSuccessDetected();
                    } else if (action == 'under_review' ||
                        action == 'pending' ||
                        action == 'in_progress' ||
                        action == 'review') {
                      controller.onVkycReviewInProgressDetected(
                        applicationId: detectedAppId.value,
                      );
                    } else if (action == 'failed' || action == 'rejected') {
                      controller.onVkycRejectedDetected();
                    } else if (action == 'cancel' || action == 'cancelled') {
                      controller.onVkycCancelDetected();
                    }
                  },
                );

                webViewController.addJavaScriptHandler(
                  handlerName: 'vkycPageDetected',
                  callback: (args) {
                    if (args.isNotEmpty && args.first is Map) {
                      final map = args.first as Map;
                      final status =
                          map['status']?.toString().toLowerCase() ?? '';
                      final appId = map['applicationId']?.toString() ?? '';
                      debugPrint(
                        "🔍 [VKYC Page Detected]: status=$status, appId=$appId",
                      );

                      if (status == 'under_review') {
                        if (!isReviewInProgressDetected.value) {
                          isReviewInProgressDetected.value = true;
                          if (appId.isNotEmpty) {
                            detectedAppId.value = appId;
                            final box = GetStorage();
                            box.write('vkyc_application_id', appId);
                          }
                          // Sync live KYC data from /api/v1/users/me once
                          if (Get.isRegistered<ApiService>()) {
                            ApiService.to.fetchUserProfile(force: true);
                          }
                        }
                      } else if (status == 'approved') {
                        if (!isApprovedDetected.value) {
                          isApprovedDetected.value = true;
                          debugPrint(
                            "🎉 [VKYC Page Detected]: APPROVED! Updating local storage and live profile.",
                          );
                          final box = GetStorage();
                          box.write('pending_vkyc_success_dialog', true);
                          box.write('is_kyc_completed', true);
                          box.write('full_kyc_completed', true);
                          box.write('kyc_status', 'completed');
                          box.write('kyc_current_level', 'FULL');

                          // Sync live KYC data from /api/v1/users/me
                          if (Get.isRegistered<ApiService>()) {
                            ApiService.to.fetchUserProfile(force: true);
                          }
                        }
                      }
                    }
                  },
                );

                webViewController.addJavaScriptHandler(
                  handlerName: 'vkycWindowClose',
                  callback: (args) {
                    debugPrint("🚪 [VKYC JS Window Close]");
                    _safetyTimer?.cancel();
                    _domCheckTimer?.cancel();
                    if (isReviewInProgressDetected.value) {
                      controller.onVkycReviewInProgressDetected(
                        applicationId: detectedAppId.value,
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
              onLoadStart: (webViewController, url) {
                hasError.value = false;
                if (url != null) {
                  _handleVkycUrl(url.toString());
                }
              },
              onProgressChanged: (webViewController, progress) {
                if (progress >= 40) {
                  isWebViewLoading.value = false;
                  _safetyTimer?.cancel();
                }
                _injectDomInspector();
              },
              onLoadStop: (webViewController, url) {
                isWebViewLoading.value = false;
                _safetyTimer?.cancel();
                _injectDomInspector();
              },
              onReceivedError: (webViewController, request, error) {
                final urlString = request.url.toString();
                debugPrint(
                  "⚠️ [VKYC WebView Error]: $urlString -> ${error.description}",
                );

                if (_handleVkycUrl(urlString)) {
                  return;
                }

                if (urlString.startsWith("transwallet://") ||
                    urlString.startsWith("about:") ||
                    urlString.startsWith("data:")) {
                  return;
                }

                isWebViewLoading.value = false;
                _safetyTimer?.cancel();
              },
              shouldOverrideUrlLoading:
                  (webViewController, navigationAction) async {
                    final uri = navigationAction.request.url;
                    if (uri != null) {
                      final urlString = uri.toString();
                      debugPrint("🌐 [VKYC WebView Navigating]: $urlString");

                      if (_handleVkycUrl(urlString)) {
                        return NavigationActionPolicy.CANCEL;
                      }
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
            ),

            // Top notification banner when Approved or Review in Progress is detected
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Obx(() {
                if (isApprovedDetected.value) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFF10B981), width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Video KYC completed successfully! Tap Done to proceed",
                            style: TextStyle(
                              color: const Color(0xFF065F46),
                              fontSize: context.responsive(12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _safetyTimer?.cancel();
                            _domCheckTimer?.cancel();
                            controller.onVkycSuccessDetected();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Done",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (isReviewInProgressDetected.value) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9C3),
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFFFDE047), width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pending_actions_rounded,
                          color: Color(0xFFCA8A04),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Verification submitted! Tap Continue below or Exit to Dashboard",
                            style: TextStyle(
                              color: const Color(0xFF854D0E),
                              fontSize: context.responsive(12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _safetyTimer?.cancel();
                            _domCheckTimer?.cancel();
                            controller.onVkycReviewInProgressDetected(
                              applicationId: detectedAppId.value,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCA8A04),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Dashboard",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ),

            // Loading indicator
            Obx(() {
              if (isWebViewLoading.value || controller.isLoading.value) {
                return Container(
                  color: const Color(0xFF0F0F1A).withValues(alpha: 0.6),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: primaryYellow),
                        if (controller.isLoading.value) ...[
                          const SizedBox(height: 16),
                          const Text(
                            "Verifying Video KYC...",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // Error display
            Obx(() {
              if (hasError.value) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Failed to Load VKYC Page",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Could not load VKYC provider page. Please try again.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                          ),
                          onPressed: () {
                            hasError.value = false;
                            isWebViewLoading.value = true;
                          },
                          child: const Text(
                            "Retry",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}
