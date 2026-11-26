import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Manage Card/managecard_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/notification_button.dart';
import 'package:transwallet/widgets/premium_visa_card.dart';

class CardDetailsPopup extends StatefulWidget {
  final Map<String, dynamic> card;
  const CardDetailsPopup({super.key, required this.card});

  @override
  State<CardDetailsPopup> createState() => _CardDetailsPopupState();
}

class _CardDetailsPopupState extends State<CardDetailsPopup> {
  bool _isLoadingSession = true;
  String? _widgetUrl;
  bool _hasWebViewError = false;
  String? _apiErrorMessage;
  String? _apiErrorCode;
  int? _apiStatusCode;
  double _loadingProgress = 0.0;
  bool _isPageLoading = true;
  final bool _showNativeView = false;
  bool _showCvv = false;
  InAppWebViewController? _webViewController;
  bool _isCallbackHandled = false;

  void _closePopup() {
    if (!mounted) return;
    try {
      _webViewController?.stopLoading();
    } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else if (Get.isDialogOpen ?? false) {
          Get.back();
        } else {
          Get.back();
        }
      } catch (e) {
        developer.log('[CardDetailsPopup] Error closing popup: $e');
        try {
          Get.back();
        } catch (_) {}
      }
    });
  }

  void _copyCardNumber() {
    final numStr =
        widget.card['fullNumber'] as String? ??
        widget.card['cardNumber'] as String? ??
        '';
    if (numStr.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: numStr));
      Get.rawSnackbar(
        message: "Card number copied",
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF111111),
        borderRadius: 14,
        margin: const EdgeInsets.all(16),
        snackStyle: SnackStyle.FLOATING,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.startExternalFlow(ExternalFlowType.customWebview);
    }
    _fetchWidgetSession();
  }

  @override
  void dispose() {
    try {
      _webViewController?.stopLoading();
      _webViewController?.clearCache();
      _webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri("about:blank")),
      );
      _webViewController = null;
    } catch (_) {}
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.finishExternalFlow(ExternalFlowType.customWebview);
    }
    super.dispose();
  }

  Future<void> _fetchWidgetSession() async {
    _isCallbackHandled = false;
    final status = widget.card['status']?.toString().toUpperCase() ?? '';
    final bool isPermBlocked =
        status == 'BLOCKED' ||
        status == 'PERMANENT_BLOCK' ||
        status == 'PERMANENTLY_BLOCKED' ||
        widget.card['isPermanentlyBlocked'] == true;
    if (isPermBlocked) {
      if (mounted) {
        setState(() {
          _isLoadingSession = false;
          _hasWebViewError = false;
        });
      }
      return;
    }

    if (Get.isRegistered<ApiService>()) {
      if (mounted) {
        setState(() {
          _isLoadingSession = true;
          _hasWebViewError = false;
          _apiErrorMessage = null;
          _apiErrorCode = null;
          _apiStatusCode = null;
          _isPageLoading = true;
          _loadingProgress = 0.0;
        });
      }

      final kitNumber =
          widget.card['kitNumber']?.toString() ?? widget.card['id']?.toString();

      final res = await ApiService.to.fetchCardWidgetSession(
        widgetType: "CARD_DETAILS",
        kitNumber: kitNumber,
        callbackUrl: "transwallet://card-details/return",
      );

      if (mounted) {
        setState(() {
          _isLoadingSession = false;
          final bool hasErr = res == null || res['hasError'] == true;
          final extractedUrl =
              res?['widgetUrl']?.toString() ??
              res?['result']?.toString() ??
              res?['url']?.toString();

          if (!hasErr && extractedUrl != null && extractedUrl.isNotEmpty) {
            _widgetUrl = extractedUrl;
            _hasWebViewError = false;
            _apiErrorMessage = null;
            _apiErrorCode = null;
            _apiStatusCode = null;
          } else {
            _hasWebViewError = true;
            _apiErrorMessage =
                res?['message']?.toString() ??
                "Unable to initialize card session.";
            _apiErrorCode = res?['code']?.toString();
            _apiStatusCode = res?['statusCode'] as int?;
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingSession = false;
          _hasWebViewError = true;
          _apiErrorMessage = "API Service not registered.";
        });
      }
    }
  }

  bool _handleCallbackUrl(String urlString) {
    if (urlString.isEmpty) return false;
    final lowerUrl = urlString.toLowerCase();
    final uri = Uri.tryParse(urlString);

    // Custom scheme deep links
    final bool isCustomScheme =
        lowerUrl.startsWith('transwallet://') ||
        lowerUrl.startsWith('ppiapp://') ||
        lowerUrl.startsWith('yappay://') ||
        lowerUrl.startsWith('app://') ||
        lowerUrl.startsWith('intent://');

    // HTTP/HTTPS callback or return patterns
    final bool isCallbackPattern =
        (urlString != _widgetUrl) &&
        (lowerUrl.contains('card-widget/return') ||
            lowerUrl.contains('card-details/return') ||
            lowerUrl.contains('card-details/close') ||
            lowerUrl.contains('card-details/cancel') ||
            lowerUrl.contains('card-details/success') ||
            lowerUrl.contains('reset-pin') ||
            lowerUrl.contains('card-pin') ||
            lowerUrl.contains('set-pin') ||
            lowerUrl.contains('callback') ||
            lowerUrl.contains('return_url'));

    if (!isCustomScheme && !isCallbackPattern) {
      return false;
    }

    developer.log(
      '[Card Details DeepLink/Callback] Intercepted URL: $urlString',
    );

    if (_isCallbackHandled) {
      return true;
    }
    _isCallbackHandled = true;

    final String? status =
        uri?.queryParameters['status'] ??
        uri?.queryParameters['result'] ??
        uri?.queryParameters['event'] ??
        uri?.queryParameters['action'] ??
        uri?.queryParameters['code'];

    final String? message =
        uri?.queryParameters['message'] ??
        uri?.queryParameters['msg'] ??
        uri?.queryParameters['desc'] ??
        uri?.queryParameters['description'];

    // 1. Reset / Set PIN trigger from card details widget
    if (lowerUrl.contains('reset-pin') ||
        lowerUrl.contains('card-pin') ||
        lowerUrl.contains('set-pin') ||
        status?.toLowerCase().contains('reset') == true ||
        status?.toLowerCase().contains('pin') == true) {
      developer.log(
        '[Card Details Callback] Triggering Reset PIN flow from card details',
      );
      _closePopup();
      Future.microtask(() {
        if (Get.isRegistered<ManagecardController>()) {
          final ctrl = Get.find<ManagecardController>();
          if (ctrl.cardData.isEmpty && widget.card.isNotEmpty) {
            ctrl.cardData.addAll(Map<String, dynamic>.from(widget.card));
          }
          ctrl.showResetPinDialog();
        } else {
          final ctrl = Get.put(ManagecardController());
          if (widget.card.isNotEmpty) {
            ctrl.cardData.addAll(Map<String, dynamic>.from(widget.card));
          }
          ctrl.showResetPinDialog();
        }
      });
      return true;
    }

    // 2. Cancellation or Close
    if (lowerUrl.contains('cancel') ||
        lowerUrl.contains('close') ||
        lowerUrl.contains('finish') ||
        lowerUrl.contains('done') ||
        status?.toLowerCase() == 'cancel' ||
        status?.toLowerCase() == 'close') {
      developer.log('[Card Details Callback] Action: CANCEL/CLOSE');
      _closePopup();
      if (lowerUrl.contains('done') || lowerUrl.contains('finish')) {
        AppSnackbar.info(message ?? 'Card details session closed.');
      }
      return true;
    }

    // 3. Error or Failure
    if (lowerUrl.contains('fail') ||
        lowerUrl.contains('error') ||
        status?.toLowerCase() == 'failed' ||
        status?.toLowerCase() == 'error' ||
        status?.toLowerCase() == 'rejected') {
      developer.log('[Card Details Callback] Status: FAILED - $message');
      _closePopup();
      AppSnackbar.error(
        message ?? 'Card widget session failed or was declined.',
      );
      return true;
    }

    // 4. Success or Successful return
    if (lowerUrl.contains('success') ||
        status?.toLowerCase() == 'success' ||
        status == '200' ||
        status == '00') {
      developer.log('[Card Details Callback] Status: SUCCESS - $message');
      _closePopup();
      AppSnackbar.success(message ?? 'Card details verified successfully.');
      return true;
    }

    // 5. General custom scheme fallback
    developer.log(
      '[Card Details Callback] Fallback custom scheme handled: $urlString',
    );
    _closePopup();
    return true;
  }

  void _processCallbackData(dynamic data) {
    developer.log('[Card Widget Session JS Callback Data] $data');
    if (data == null) return;

    String? status;
    String? action;
    String? msg;

    if (data is Map) {
      final mapData = Map<String, dynamic>.from(data);
      status =
          mapData['status']?.toString() ??
          mapData['event']?.toString() ??
          mapData['result']?.toString() ??
          mapData['code']?.toString();
      action = mapData['action']?.toString();
      msg =
          mapData['message']?.toString() ??
          mapData['msg']?.toString() ??
          mapData['desc']?.toString();
    } else if (data is String) {
      final lower = data.toLowerCase();
      if (lower.contains('reset-pin') ||
          lower.contains('reset_pin') ||
          lower.contains('card-pin') ||
          lower.contains('set_pin')) {
        _handleCallbackUrl('transwallet://reset-pin');
        return;
      }
      if (lower.contains('close') || lower.contains('cancel')) {
        _handleCallbackUrl('transwallet://card-details/close');
        return;
      }
      if (lower.contains('success') || lower.contains('200')) {
        _handleCallbackUrl('transwallet://card-details/success');
        return;
      }
      if (lower.contains('fail') || lower.contains('error')) {
        _handleCallbackUrl('transwallet://card-details/fail');
        return;
      }
      msg = data;
    }

    final lowerStatus = status?.toLowerCase() ?? '';
    final lowerAction = action?.toLowerCase() ?? '';

    if (lowerStatus.contains('reset') ||
        lowerAction.contains('reset') ||
        lowerAction.contains('pin')) {
      _handleCallbackUrl('transwallet://reset-pin');
    } else if (lowerStatus == 'close' ||
        lowerStatus == 'cancel' ||
        lowerAction == 'close' ||
        lowerAction == 'cancel') {
      _handleCallbackUrl('transwallet://card-details/close');
    } else if (lowerStatus == 'success' ||
        lowerStatus == '200' ||
        lowerStatus == '00') {
      _handleCallbackUrl('transwallet://card-details/success');
    } else if (lowerStatus == 'failed' || lowerStatus == 'error') {
      final encodedMsg = Uri.encodeComponent(msg ?? 'Operation failed');
      _handleCallbackUrl('transwallet://card-details/fail?message=$encodedMsg');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardData = widget.card;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        centerTitle: true,
        title: Text(
          "Card Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: context.responsive(18),
            letterSpacing: 0,
          ),
        ),
        actions: [
          if (_widgetUrl != null && !_hasWebViewError)
            // IconButton(
            //   icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            //   tooltip: "Reload",
            //   onPressed: () {
            //     _webViewController?.reload();
            //   },
            // ),
            TextButton(
              onPressed: () {
                Get.toNamed('/managecard', arguments: cardData);
              },
              child: Padding(
                padding: EdgeInsets.only(
                  left: context.responsive(8),
                  right: context.responsive(8),
                ),
                child: Container(
                  padding: EdgeInsets.all(context.responsive(8)),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromRGBO(0, 0, 0, 0.05),
                      width: 1.0,
                    ),
                    color: const Color.fromRGBO(255, 255, 255, 1),
                  ),
                  child: SvgPicture.asset(
                    "assets/managecard.svg",
                    height: context.responsive(22),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final status = widget.card['status']?.toString().toUpperCase() ?? '';
    final bool isPermBlocked =
        status == 'BLOCKED' ||
        status == 'PERMANENT_BLOCK' ||
        status == 'PERMANENTLY_BLOCKED' ||
        widget.card['isPermanentlyBlocked'] == true;

    if (isPermBlocked) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.responsive(28)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(context.responsive(20)),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block_rounded,
                  color: Colors.red.shade700,
                  size: context.responsive(48),
                ),
              ),
              SizedBox(height: context.responsive(18)),
              Text(
                "Card Permanently Blocked",
                style: TextStyle(
                  fontSize: context.responsive(18),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: context.responsive(8)),
              Text(
                "This card has been permanently blocked. You cannot view card details or use it for transactions. Please request a new card.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.responsive(13),
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              SizedBox(height: context.responsive(24)),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsive(32),
                    vertical: context.responsive(12),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.responsive(20)),
                  ),
                ),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingSession && !_showNativeView) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: primaryYellow,
              strokeWidth: 3,
            ),
            SizedBox(height: context.responsive(16)),
            Text(
              "Loading Card Details...",
              style: TextStyle(
                fontSize: context.responsive(15),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: context.responsive(6)),
            Text(
              "Connecting to secure payment session",
              style: TextStyle(
                fontSize: context.responsive(12),
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_showNativeView) {
      return _buildNativeCardView(
        context,
        isFallback:
            _hasWebViewError || _widgetUrl == null || _widgetUrl!.isEmpty,
      );
    }

    if (_hasWebViewError || _widgetUrl == null || _widgetUrl!.isEmpty) {
      return _buildErrorState(context);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_widgetUrl!)),
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<VerticalDragGestureRecognizer>(
                () => VerticalDragGestureRecognizer(),
              ),
              Factory<HorizontalDragGestureRecognizer>(
                () => HorizontalDragGestureRecognizer(),
              ),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            },
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              transparentBackground: true,
              useShouldOverrideUrlLoading: true,
              useOnRenderProcessGone: true,
              supportMultipleWindows: true,
              allowsInlineMediaPlayback: true,
              useHybridComposition: true,
              allowFileAccessFromFileURLs: true,
              allowUniversalAccessFromFileURLs: true,
              mediaPlaybackRequiresUserGesture: false,
              clearCache: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              controller.addJavaScriptHandler(
                handlerName: 'cardCallback',
                callback: (args) {
                  developer.log('[Card Widget JS Callback] Data: $args');
                  if (args.isNotEmpty) {
                    _processCallbackData(args.first);
                  }
                },
              );
              controller.addJavaScriptHandler(
                handlerName: 'onSessionComplete',
                callback: (args) {
                  developer.log(
                    '[Card Widget JS Session Complete] Data: $args',
                  );
                  if (args.isNotEmpty) {
                    _processCallbackData(args.first);
                  }
                },
              );
              controller.addJavaScriptHandler(
                handlerName: 'WidgetCallback',
                callback: (args) {
                  developer.log('[Card Widget JS WidgetCallback] Data: $args');
                  if (args.isNotEmpty) {
                    _processCallbackData(args.first);
                  }
                },
              );
              controller.addJavaScriptHandler(
                handlerName: 'CardWidget',
                callback: (args) {
                  developer.log('[Card Widget JS CardWidget] Data: $args');
                  if (args.isNotEmpty) {
                    _processCallbackData(args.first);
                  }
                },
              );
              controller.addJavaScriptHandler(
                handlerName: 'CardPinCallback',
                callback: (args) {
                  developer.log('[Card Widget JS CardPinCallback] Data: $args');
                  _handleCallbackUrl('transwallet://reset-pin');
                },
              );
            },
            onProgressChanged: (controller, progress) {
              if (mounted) {
                setState(() {
                  _loadingProgress = progress / 100.0;
                  if (progress >= 100) {
                    _isPageLoading = false;
                  }
                });
              }
            },
            onRenderProcessGone: (controller, detail) async {
              developer.log(
                '[Card Widget WebView] Render process gone (didCrash: ${detail.didCrash})',
              );
              if (mounted) {
                setState(() {
                  _hasWebViewError = true;
                  _apiErrorMessage =
                      'Card display session was closed by the system. Please tap to reload.';
                });
              }
            },
            onReceivedError: (controller, request, error) {
              final urlString = request.url.toString();
              developer.log(
                '[Card Widget WebView Error] $urlString -> ${error.description}',
              );
              if (_handleCallbackUrl(urlString)) {
                return;
              }
              if (request.isForMainFrame ?? true) {
                if (mounted) {
                  setState(() {
                    _hasWebViewError = true;
                    _apiErrorMessage = error.description;
                  });
                }
              }
            },
            onReceivedHttpError: (controller, request, response) {
              final urlString = request.url.toString();
              developer.log(
                '[Card Widget WebView HTTP Error] $urlString -> ${response.statusCode}',
              );
              if (_handleCallbackUrl(urlString)) {
                return;
              }
              if ((request.isForMainFrame ?? true) &&
                  response.statusCode != null &&
                  response.statusCode! >= 400) {
                if (mounted) {
                  setState(() {
                    _hasWebViewError = true;
                    _apiErrorMessage =
                        'HTTP ${response.statusCode}: ${response.reasonPhrase ?? "Error loading widget page"}';
                    _apiStatusCode = response.statusCode;
                  });
                }
              }
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (uri != null) {
                final urlString = uri.toString();
                developer.log(
                  '[Card Widget Navigation] Intercepted => $urlString',
                );
                final handled = _handleCallbackUrl(urlString);
                if (handled) {
                  return NavigationActionPolicy.CANCEL;
                }
              }
              return NavigationActionPolicy.ALLOW;
            },
            onLoadStart: (controller, url) {
              if (url != null) {
                final urlString = url.toString();
                developer.log('[Card Widget Load Start] => $urlString');
                if (_handleCallbackUrl(urlString)) {
                  return;
                }
              }
              if (mounted) {
                setState(() => _isPageLoading = true);
              }
            },
            onLoadStop: (controller, url) async {
              if (mounted) {
                setState(() => _isPageLoading = false);
              }
              if (url != null) {
                final urlString = url.toString();
                developer.log('[Card Widget Load Stop] => $urlString');
                if (_handleCallbackUrl(urlString)) {
                  return;
                }
              }
              try {
                await controller.evaluateJavascript(
                  source: """
                  (function() {
                    var viewport = document.querySelector('meta[name="viewport"]');
                    if (!viewport) {
                      viewport = document.createElement('meta');
                      viewport.name = 'viewport';
                      viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                      document.getElementsByTagName('head')[0].appendChild(viewport);
                    }

                    // PostMessage cross-origin bridge for card widget events
                    window.addEventListener('message', function(event) {
                      if (event && event.data) {
                        var dataStr = typeof event.data === 'string' ? event.data : JSON.stringify(event.data);
                        if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                          window.flutter_inappwebview.callHandler('cardCallback', dataStr);
                          window.flutter_inappwebview.callHandler('WidgetCallback', dataStr);
                          window.flutter_inappwebview.callHandler('CardWidget', dataStr);
                        }
                        var lower = dataStr.toLowerCase();
                        if (lower.indexOf('reset-pin') !== -1 || lower.indexOf('reset_pin') !== -1 || lower.indexOf('card-pin') !== -1 || lower.indexOf('set_pin') !== -1) {
                          window.location.href = 'transwallet://reset-pin';
                        } else if (lower.indexOf('close') !== -1 || lower.indexOf('cancel') !== -1 || lower.indexOf('dismiss') !== -1) {
                          window.location.href = 'transwallet://card-details/close';
                        } else if (lower.indexOf('success') !== -1 || lower.indexOf('200') !== -1) {
                          window.location.href = 'transwallet://card-details/success';
                        }
                      }
                    });

                    window.addEventListener('focusin', function(e) {
                      if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'SELECT' || e.target.tagName === 'TEXTAREA')) {
                        setTimeout(function() {
                          e.target.scrollIntoView({ behavior: 'smooth', block: 'center' });
                        }, 250);
                      }
                    });
                  })();
                  """,
                );
              } catch (e) {
                developer.log('[Card Widget JS Inject Error] $e');
              }
            },
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED,
              );
            },
            onConsoleMessage: (controller, message) {
              developer.log('[Card Widget WebView Console] ${message.message}');
            },
          ),
        ),
        if (_isPageLoading && _loadingProgress < 1.0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _loadingProgress > 0 ? _loadingProgress : null,
              backgroundColor: Colors.transparent,
              color: primaryYellow,
              minHeight: 3,
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final message =
        _apiErrorMessage ?? "Unable to load card session. Please try again.";
    final code = _apiErrorCode;
    final status = _apiStatusCode;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive(24),
          vertical: context.responsive(20),
        ),
        child: Container(
          padding: EdgeInsets.all(context.responsive(24)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.responsive(20)),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(context.responsive(16)),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: const Color(0xFFD32F2F),
                  size: context.responsive(36),
                ),
              ),
              SizedBox(height: context.responsive(16)),
              Text(
                "Unable to Load Card Details",
                style: TextStyle(
                  fontSize: context.responsive(18),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.responsive(6)),
              Text(
                "The secure payment session could not be initialized.",
                style: TextStyle(
                  fontSize: context.responsive(13),
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.responsive(18)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.responsive(14)),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(context.responsive(12)),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: Color(0xFFE53935),
                            ),
                            SizedBox(width: context.responsive(6)),
                            Text(
                              code != null && code.isNotEmpty
                                  ? code
                                  : "Server Error",
                              style: TextStyle(
                                fontSize: context.responsive(12),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFC62828),
                              ),
                            ),
                          ],
                        ),
                        if (status != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.responsive(8),
                              vertical: context.responsive(2),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Status $status",
                              style: TextStyle(
                                fontSize: context.responsive(11),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFC62828),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: context.responsive(8)),
                    SelectableText(
                      message,
                      style: TextStyle(
                        fontSize: context.responsive(12),
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.responsive(22)),
              SizedBox(
                width: double.infinity,
                height: context.responsive(46),
                child: ElevatedButton.icon(
                  onPressed: _fetchWidgetSession,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    "Retry",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.responsive(12),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: context.responsive(10)),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  "Close",
                  style: TextStyle(
                    fontSize: context.responsive(13),
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNativeCardView(BuildContext context, {bool isFallback = false}) {
    final cardData = widget.card;
    final cardNumber =
        cardData['fullNumber'] as String? ??
        cardData['cardNumber'] as String? ??
        cardData['maskedNumber'] as String? ??
        (cardData['last4'] != null
            ? '•••• •••• •••• ${cardData['last4']}'
            : '');
    final cardHolder =
        GetStorage().read('name') ??
        GetStorage().read('userName') ??
        cardData['holder'] as String? ??
        cardData['cardHolder'] as String? ??
        '';
    final rawExpiry =
        cardData['expiryMmYy']?.toString() ??
        cardData['expiry'] as String? ??
        '';
    String expiry = '--/--';
    final digits = rawExpiry.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 4) {
      expiry = '${digits.substring(0, 2)}/${digits.substring(2, 4)}';
    } else if (rawExpiry.contains('/')) {
      expiry = rawExpiry;
    } else if (rawExpiry.isNotEmpty) {
      expiry = rawExpiry;
    }
    final cvv = cardData['cvv'] as String? ?? '';
    final brand =
        cardData['brand'] as String? ?? cardData['network'] as String?;
    final bgImage = PremiumVisaCard.resolveCardBgImage(
      brand: brand,
      bgImage: cardData['bgImage'] as String?,
    );

    return Column(
      children: [
        if (isFallback)
          Container(
            margin: EdgeInsets.fromLTRB(
              context.responsive(20),
              context.responsive(12),
              context.responsive(20),
              0,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive(14),
              vertical: context.responsive(10),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(context.responsive(12)),
              border: Border.all(color: const Color(0xFFFFD54F)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFF57F17),
                  size: 20,
                ),
                SizedBox(width: context.responsive(10)),
                Expanded(
                  child: Text(
                    "Displaying secure card details. Web widget session is currently unavailable.",
                    style: TextStyle(
                      fontSize: context.responsive(12),
                      color: const Color(0xFF5D4037),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _fetchWidgetSession,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(
                      context.responsive(50),
                      context.responsive(30),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "Retry",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(context.responsive(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(context.responsive(22)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(context.responsive(22)),
                    image: DecorationImage(
                      image: AssetImage(bgImage),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/WU.png',
                            height: context.responsive(22),
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                      SizedBox(height: context.responsive(20)),
                      Container(
                        width: context.responsive(45),
                        height: context.responsive(30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            context.responsive(6),
                          ),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFECB3), Color(0xFFE5C158)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      SizedBox(height: context.responsive(20)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cardNumber.isNotEmpty
                                ? cardNumber
                                : '•••• •••• •••• ••••',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: context.responsive(18),
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: _copyCardNumber,
                            child: Container(
                              padding: EdgeInsets.all(context.responsive(6)),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(
                                  context.responsive(8),
                                ),
                              ),
                              child: Icon(
                                Icons.copy_rounded,
                                color: Colors.white,
                                size: context.responsive(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.responsive(20)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "CARD HOLDER",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: context.responsive(10),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: context.responsive(3)),
                                Text(
                                  cardHolder.isNotEmpty
                                      ? cardHolder
                                      : "CARDHOLDER",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: context.responsive(13),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(height: context.responsive(6)),
                                Row(
                                  children: [
                                    Text(
                                      "VALID THRU  ",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: context.responsive(9),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      expiry,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: context.responsive(12),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "CVV",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: context.responsive(10),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: context.responsive(3)),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _showCvv = !_showCvv),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _showCvv
                                          ? (cvv.isNotEmpty ? cvv : '•••')
                                          : "•••",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: context.responsive(13),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: context.responsive(6)),
                                    Icon(
                                      _showCvv
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: Colors.white70,
                                      size: context.responsive(16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.responsive(20)),

                // Security notice badge
                Container(
                  padding: EdgeInsets.all(context.responsive(14)),
                  decoration: BoxDecoration(
                    color: primaryLightYellow.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(context.responsive(14)),
                    border: Border.all(
                      color: primaryYellow.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security_rounded,
                        color: Colors.black87,
                        size: context.responsive(20),
                      ),
                      SizedBox(width: context.responsive(10)),
                      Expanded(
                        child: Text(
                          "Card details are protected and encrypted according to safety standards.",
                          style: TextStyle(
                            fontSize: context.responsive(12),
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Action Buttons
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive(20),
            vertical: context.responsive(14),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111111),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: EdgeInsets.symmetric(
                      vertical: context.responsive(14),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.responsive(14),
                      ),
                    ),
                  ),
                  child: Text(
                    "Close",
                    style: TextStyle(
                      fontSize: context.responsive(14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.responsive(12)),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed('/managecard', arguments: cardData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    foregroundColor: const Color(0xFF0F1013),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      vertical: context.responsive(14),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.responsive(14),
                      ),
                    ),
                  ),
                  child: Text(
                    "Manage Card",
                    style: TextStyle(
                      fontSize: context.responsive(14),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FullCardDetailsPopup extends StatefulWidget {
  final Map<String, dynamic>? card;
  const FullCardDetailsPopup({super.key, this.card});

  @override
  State<FullCardDetailsPopup> createState() => _FullCardDetailsPopupState();
}

class _FullCardDetailsPopupState extends State<FullCardDetailsPopup> {
  bool _showCvv = false;

  void _copyCardNumber() {
    final numStr =
        widget.card?['fullNumber'] as String? ??
        widget.card?['cardNumber'] as String? ??
        '';
    if (numStr.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: numStr));
      Get.rawSnackbar(
        message: "Card number copied",
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF111111),
        borderRadius: 14,
        margin: const EdgeInsets.all(16),
        snackStyle: SnackStyle.FLOATING,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardData = widget.card ?? {};
    final cardNumber =
        cardData['fullNumber'] as String? ??
        cardData['cardNumber'] as String? ??
        cardData['maskedNumber'] as String? ??
        (cardData['last4'] != null
            ? '•••• •••• •••• ${cardData['last4']}'
            : '');
    final cardHolder =
        GetStorage().read('name') ??
        GetStorage().read('userName') ??
        cardData['holder'] as String? ??
        cardData['cardHolder'] as String? ??
        'CARDHOLDER';
    final rawExpiry =
        cardData['expiryMmYy']?.toString() ??
        cardData['expiry'] as String? ??
        '';
    String expiry = '--/--';
    final digits = rawExpiry.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 4) {
      expiry = '${digits.substring(0, 2)}/${digits.substring(2, 4)}';
    } else if (rawExpiry.contains('/')) {
      expiry = rawExpiry;
    } else if (rawExpiry.isNotEmpty) {
      expiry = rawExpiry;
    }
    final cvv = cardData['cvv'] as String? ?? '';
    final brand =
        cardData['brand'] as String? ?? cardData['network'] as String?;
    final bgImage = PremiumVisaCard.resolveCardBgImage(
      brand: brand,
      bgImage: cardData['bgImage'] as String?,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        centerTitle: true,
        title: Text(
          cardData['label']?.toString() ?? "Card Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: context.responsive(18),
            letterSpacing: 0,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: context.responsive(18)),
            child: const Center(child: NotificationButton()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(context.responsive(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.responsive(22)),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          context.responsive(22),
                        ),
                        image: DecorationImage(
                          image: AssetImage(bgImage),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/WU.png',
                                height: context.responsive(22),
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                          SizedBox(height: context.responsive(20)),
                          Container(
                            width: context.responsive(45),
                            height: context.responsive(30),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                context.responsive(6),
                              ),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFECB3), Color(0xFFE5C158)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          SizedBox(height: context.responsive(20)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                cardNumber,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.responsive(18),
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              GestureDetector(
                                onTap: _copyCardNumber,
                                child: Container(
                                  padding: EdgeInsets.all(
                                    context.responsive(6),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(
                                      context.responsive(8),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    color: Colors.white,
                                    size: context.responsive(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.responsive(20)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "CARD HOLDER",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: context.responsive(10),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: context.responsive(3)),
                                    Text(
                                      cardHolder,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: context.responsive(13),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    SizedBox(height: context.responsive(6)),
                                    Row(
                                      children: [
                                        Text(
                                          "VALID THRU  ",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: context.responsive(9),
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Text(
                                          expiry,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: context.responsive(12),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "CVV",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: context.responsive(10),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: context.responsive(3)),
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _showCvv = !_showCvv),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _showCvv
                                              ? (cvv.isNotEmpty ? cvv : '•••')
                                              : "•••",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: context.responsive(13),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: context.responsive(6)),
                                        Icon(
                                          _showCvv
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded,
                                          color: Colors.white70,
                                          size: context.responsive(16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.responsive(20)),

                    // Security notice badge
                    Container(
                      padding: EdgeInsets.all(context.responsive(14)),
                      decoration: BoxDecoration(
                        color: primaryLightYellow.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(
                          context.responsive(14),
                        ),
                        border: Border.all(
                          color: primaryYellow.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.security_rounded,
                            color: Colors.black87,
                            size: context.responsive(20),
                          ),
                          SizedBox(width: context.responsive(10)),
                          Expanded(
                            child: Text(
                              "Card details are protected and encrypted according to safety standards.",
                              style: TextStyle(
                                fontSize: context.responsive(12),
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive(20),
                vertical: context.responsive(14),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
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
                          borderRadius: BorderRadius.circular(
                            context.responsive(12),
                          ),
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
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.toNamed('/managecard', arguments: cardData);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: context.responsive(14),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            context.responsive(12),
                          ),
                        ),
                      ),
                      child: Text(
                        "Manage Card",
                        style: TextStyle(
                          color: const Color(0xFF0F1013),
                          fontWeight: FontWeight.w700,
                          fontSize: context.responsive(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
