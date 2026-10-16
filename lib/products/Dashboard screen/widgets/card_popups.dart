import 'dart:developer' as developer;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

const List<Map<String, dynamic>> kCards = [];

class CardDetailsPopup extends StatefulWidget {
  final Map<String, dynamic> card;
  const CardDetailsPopup({super.key, required this.card});

  @override
  State<CardDetailsPopup> createState() => _CardDetailsPopupState();
}

class _CardDetailsPopupState extends State<CardDetailsPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  bool _isLoadingSession = true;
  String? _widgetUrl;
  bool _hasWebViewError = false;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutBack);
    _scaleCtrl.forward();
    _fetchWidgetSession();
  }

  Future<void> _fetchWidgetSession() async {
    if (Get.isRegistered<ApiService>()) {
      setState(() => _isLoadingSession = true);
      final res = await ApiService.to.fetchCardWidgetSession(
        widgetType: "CARD_DETAILS",
      );
      if (mounted) {
        setState(() {
          _isLoadingSession = false;
          if (res != null) {
            _widgetUrl =
                "https://transcorpint.com/assets/app/M2P-VIEW-WIDGET-2.html";
            // res['widgetUrl']?.toString();
          }
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingSession = false);
    }
  }

  bool _handleCallbackUrl(String urlString) {
    if (urlString.isEmpty) return false;
    final lowerUrl = urlString.toLowerCase();
    final uri = Uri.tryParse(urlString);

    final isCallback =
        lowerUrl.contains('callback') ||
        lowerUrl.contains('success') ||
        lowerUrl.contains('cancel') ||
        lowerUrl.contains('failure') ||
        lowerUrl.contains('failed') ||
        lowerUrl.contains('close') ||
        lowerUrl.contains('finish') ||
        lowerUrl.contains('done') ||
        lowerUrl.contains('redirect') ||
        lowerUrl.contains('return_url') ||
        lowerUrl.startsWith('transwallet://') ||
        lowerUrl.startsWith('app://') ||
        lowerUrl.startsWith('yappay://');

    if (isCallback) {
      developer.log(
        '[Card Widget Callback Managed] Intercepted URL: $urlString',
      );

      final String? status =
          uri?.queryParameters['status'] ??
          uri?.queryParameters['result'] ??
          uri?.queryParameters['event'] ??
          uri?.queryParameters['action'] ??
          uri?.queryParameters['code'];

      final String? message =
          uri?.queryParameters['message'] ??
          uri?.queryParameters['msg'] ??
          uri?.queryParameters['desc'];

      if (lowerUrl.contains('success') ||
          status?.toLowerCase() == 'success' ||
          status == '200' ||
          status == '00') {
        developer.log('[Card Widget Callback] Status: SUCCESS - $message');
        AppSnackbar.showSuccess(
          title: 'Card Details',
          message: message ?? 'Card widget session executed successfully.',
        );
      } else if (lowerUrl.contains('cancel') ||
          lowerUrl.contains('close') ||
          status?.toLowerCase() == 'cancel' ||
          status?.toLowerCase() == 'close') {
        developer.log('[Card Widget Callback] Action: CANCEL/CLOSE');
      } else if (lowerUrl.contains('fail') ||
          lowerUrl.contains('error') ||
          status?.toLowerCase() == 'failed' ||
          status?.toLowerCase() == 'error') {
        developer.log('[Card Widget Callback] Status: FAILED - $message');
        AppSnackbar.showError(
          title: 'Card Widget Error',
          message: message ?? 'Card widget session failed or was declined.',
        );
      }

      if (lowerUrl.startsWith('transwallet://') ||
          lowerUrl.startsWith('app://') ||
          lowerUrl.startsWith('yappay://') ||
          lowerUrl.startsWith('intent://')) {
        return true;
      }
    }
    return false;
  }

  void _processCallbackData(dynamic data) {
    developer.log('[Card Widget Session JS Callback Data] $data');
    if (data is Map) {
      final mapData = Map<String, dynamic>.from(data);
      final status =
          mapData['status']?.toString() ?? mapData['event']?.toString();
      final msg = mapData['message']?.toString();
      if (status?.toLowerCase() == 'success' || status == '200') {
        AppSnackbar.showSuccess(
          title: 'Card Details',
          message: msg ?? 'Widget operation completed successfully.',
        );
      } else if (status?.toLowerCase() == 'failed' ||
          status?.toLowerCase() == 'error') {
        AppSnackbar.showError(
          title: 'Card Widget Error',
          message: msg ?? 'Widget operation failed.',
        );
      }
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardData = widget.card;
    final bgImagePath = cardData['bgImage']?.toString();

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withValues(alpha: 0.45)),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCardWebView(bgImagePath),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              Get.back();
                              Get.toNamed(
                                '/managecard',
                                arguments: widget.card,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Text(
                                'Manage',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWebView(String? bgImagePath) {
    if (_isLoadingSession) {
      return Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          image: bgImagePath != null && bgImagePath.isNotEmpty
              ? DecorationImage(
                  image: AssetImage(bgImagePath),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.6),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
            SizedBox(height: 14),
            Text(
              "Loading Card Details...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_widgetUrl != null && _widgetUrl!.isNotEmpty && !_hasWebViewError) {
      return Container(
        width: double.infinity,
        height: 210,
        decoration: BoxDecoration(
          // color: const Color(0xFF111111),
          // borderRadius: BorderRadius.circular(24),
          // border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_widgetUrl!)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              transparentBackground: true,
              useShouldOverrideUrlLoading: true,
              supportMultipleWindows: true,
              allowsInlineMediaPlayback: true,
            ),
            onWebViewCreated: (controller) {
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
            },
            onReceivedError: (controller, request, error) {
              developer.log('[Card Widget WebView Error] ${error.description}');
              if (request.isForMainFrame ?? true) {
                if (mounted) setState(() => _hasWebViewError = true);
              }
            },
            onReceivedHttpError: (controller, request, response) {
              developer.log(
                '[Card Widget WebView HTTP Error] ${response.statusCode}',
              );
              if (response.statusCode != null && response.statusCode! >= 400) {
                if (mounted) setState(() => _hasWebViewError = true);
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
                _handleCallbackUrl(urlString);
              }
            },
            onLoadStop: (controller, url) {
              if (url != null) {
                final urlString = url.toString();
                developer.log('[Card Widget Load Stop] => $urlString');
                _handleCallbackUrl(urlString);
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
      );
    }

    return Container(
      width: double.infinity,
      height: 225,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        image: bgImagePath != null && bgImagePath.isNotEmpty
            ? DecorationImage(
                image: AssetImage(bgImagePath),
                fit: BoxFit.fitHeight,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.75),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.credit_card, color: primaryLightYellow, size: 36),
            const SizedBox(height: 10),
            const Text(
              "Card Details Session",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Secure widget session loading...",
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _fetchWidgetSession,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Retry Session",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullCardDetailsPopup extends StatefulWidget {
  final Map<String, dynamic>? card;
  const FullCardDetailsPopup({super.key, this.card});

  @override
  State<FullCardDetailsPopup> createState() => _FullCardDetailsPopupState();
}

class _FullCardDetailsPopupState extends State<FullCardDetailsPopup>
    with SingleTickerProviderStateMixin {
  bool _showCvv = false;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutBack);
    _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

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
        '';
    final cardHolder =
        GetStorage().read('name') ??
        cardData['holder'] as String? ??
        cardData['cardHolder'] as String? ??
        '';
    final expiry = cardData['expiry'] as String? ?? '';
    final cvv = cardData['cvv'] as String? ?? '';
    final bgImage =
        cardData['bgImage'] as String? ?? 'assets/unioncardblack.webp';

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withOpacity(0.45)),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        image: DecorationImage(
                          image: AssetImage(bgImage),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFCC00).withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/WU.png',
                                    height: 22,
                                    fit: BoxFit.contain,
                                  ),
                                  Image.asset(
                                    'assets/WHITE TRANSCORP .png',
                                    height: 14,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: 45,
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFECB3),
                                      Color(0xFFE5C158),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    cardNumber,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _copyCardNumber,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.copy_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "CARD HOLDER",
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          cardHolder,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Text(
                                              "VALID THRU  ",
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            Text(
                                              expiry,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "CVV",
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _showCvv = !_showCvv,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _showCvv
                                                  ? (cvv.isNotEmpty
                                                        ? cvv
                                                        : '•••')
                                                  : "•••",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              _showCvv
                                                  ? Icons.visibility_rounded
                                                  : Icons
                                                        .visibility_off_rounded,
                                              color: Colors.white70,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Image.asset(
                                    'assets/VisaFree.png',
                                    height: 18,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              "Close",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            Get.back();
                            Get.toNamed('/managecard', arguments: cardData);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCC00),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFCC00,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Manage',
                              style: TextStyle(
                                color: Color(0xFF0F1013),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
