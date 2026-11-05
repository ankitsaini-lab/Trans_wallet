import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/services/api_service.dart';
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
  bool _showNativeView = false;
  bool _showCvv = false;
  InAppWebViewController? _webViewController;

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
    _fetchWidgetSession();
  }

  Future<void> _fetchWidgetSession() async {
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
      setState(() {
        _isLoadingSession = true;
        _hasWebViewError = false;
        _apiErrorMessage = null;
        _apiErrorCode = null;
        _apiStatusCode = null;
        _isPageLoading = true;
        _loadingProgress = 0.0;
      });

      final kitNumber =
          widget.card['kitNumber']?.toString() ?? widget.card['id']?.toString();

      final res = await ApiService.to.fetchCardWidgetSession(
        widgetType: "CARD_DETAILS",
        kitNumber: kitNumber,
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
          // if (_widgetUrl != null && !_hasWebViewError) ...[
          //   if (!_showNativeView)
          //     IconButton(
          //       icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
          //       tooltip: "Reload",
          //       onPressed: () {
          //         _webViewController?.reload();
          //       },
          //     ),
          // ],
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
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              transparentBackground: true,
              useShouldOverrideUrlLoading: true,
              supportMultipleWindows: true,
              allowsInlineMediaPlayback: true,
              useHybridComposition: true,
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
            onReceivedError: (controller, request, error) {
              developer.log('[Card Widget WebView Error] ${error.description}');
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
              developer.log(
                '[Card Widget WebView HTTP Error] ${response.statusCode}',
              );
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
              if (mounted) {
                setState(() => _isPageLoading = true);
              }
              if (url != null) {
                final urlString = url.toString();
                developer.log('[Card Widget Load Start] => $urlString');
                _handleCallbackUrl(urlString);
              }
            },
            onLoadStop: (controller, url) {
              if (mounted) {
                setState(() => _isPageLoading = false);
              }
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
