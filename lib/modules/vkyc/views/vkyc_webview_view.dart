import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:transwallet/modules/vkyc/controllers/vkyc_controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/constsize.dart';

class VkycWebviewView extends GetView<VkycController> {
  const VkycWebviewView({super.key});

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
    
    <button class="btn btn-primary" onclick="triggerVkyc('success')">Start / Complete VKYC</button>
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

  @override
  Widget build(BuildContext context) {
    final RxBool isWebViewLoading = true.obs;
    final RxBool hasError = false.obs;

    // Fast safety timer to ensure loader dismisses smoothly
    Timer? safetyTimer;
    safetyTimer = Timer(const Duration(milliseconds: 500), () {
      isWebViewLoading.value = false;
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        safetyTimer?.cancel();
        if (didPop) {
          controller.onClosePressed();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: appBarGradient),
          ),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              safetyTimer?.cancel();
              controller.onClosePressed();
            },
          ),
          title: Text(
            "Video KYC",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: context.responsive(18),
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialData: InAppWebViewInitialData(
                data: vkycHtmlContent,
                mimeType: 'text/html',
                encoding: 'utf-8',
                baseUrl: WebUri('about:blank'),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                transparentBackground: true,
              ),
              onWebViewCreated: (webViewController) {
                webViewController.addJavaScriptHandler(
                  handlerName: 'vkycAction',
                  callback: (args) {
                    final action = args.isNotEmpty ? args.first.toString() : '';
                    debugPrint("⚡ [VKYC JS Bridge Action]: $action");
                    safetyTimer?.cancel();
                    if (action == 'success') {
                      controller.onVkycSuccessDetected();
                    } else if (action == 'cancel') {
                      controller.onVkycCancelDetected();
                    }
                  },
                );
              },
              onLoadStart: (webViewController, url) {
                hasError.value = false;
                if (url != null) {
                  final urlString = url.toString();
                  if (urlString.startsWith("transwallet://vkyc/success")) {
                    safetyTimer?.cancel();
                    controller.onVkycSuccessDetected();
                  } else if (urlString.startsWith("transwallet://vkyc/cancel")) {
                    safetyTimer?.cancel();
                    controller.onVkycCancelDetected();
                  }
                }
              },
              onProgressChanged: (webViewController, progress) {
                if (progress >= 40) {
                  isWebViewLoading.value = false;
                  safetyTimer?.cancel();
                }
              },
              onLoadStop: (webViewController, url) {
                isWebViewLoading.value = false;
                safetyTimer?.cancel();
              },
              onReceivedError: (webViewController, request, error) {
                final urlString = request.url.toString();
                debugPrint("⚠️ [VKYC WebView Error]: $urlString -> ${error.description}");

                if (urlString.startsWith("transwallet://vkyc/success")) {
                  safetyTimer?.cancel();
                  controller.onVkycSuccessDetected();
                  return;
                } else if (urlString.startsWith("transwallet://vkyc/cancel")) {
                  safetyTimer?.cancel();
                  controller.onVkycCancelDetected();
                  return;
                }

                // Ignore non-fatal ERR_NAME_NOT_RESOLVED / unknown scheme errors for local test content
                if (urlString.startsWith("transwallet://") || urlString.startsWith("about:") || urlString.startsWith("data:")) {
                  return;
                }

                isWebViewLoading.value = false;
                safetyTimer?.cancel();
              },
              shouldOverrideUrlLoading: (webViewController, navigationAction) async {
                final uri = navigationAction.request.url;
                if (uri != null) {
                  final urlString = uri.toString();
                  debugPrint("🌐 [VKYC WebView Navigating]: $urlString");

                  if (urlString.startsWith("transwallet://vkyc/success")) {
                    safetyTimer?.cancel();
                    controller.onVkycSuccessDetected();
                    return NavigationActionPolicy.CANCEL;
                  } else if (urlString.startsWith("transwallet://vkyc/cancel")) {
                    safetyTimer?.cancel();
                    controller.onVkycCancelDetected();
                    return NavigationActionPolicy.CANCEL;
                  }
                }
                return NavigationActionPolicy.ALLOW;
              },
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
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          "Failed to Load VKYC Page",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Could not load VKYC provider page. Please try again.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
                          onPressed: () {
                            hasError.value = false;
                            isWebViewLoading.value = true;
                          },
                          child: const Text("Retry", style: TextStyle(color: Colors.white)),
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


