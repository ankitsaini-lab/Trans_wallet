import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'pdf_viewer_screen.dart';

class CommonWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const CommonWebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<CommonWebViewScreen> createState() => _CommonWebViewScreenState();
}

class _CommonWebViewScreenState extends State<CommonWebViewScreen> {
  InAppWebViewController? webViewController;
  double progress = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    developer.log("WebView Screen Opened for URL => ${widget.url}");
  }

  bool _isPdfUrl(String urlString) {
    final lowerUrl = urlString.toLowerCase();
    return lowerUrl.endsWith('.pdf') || 
           lowerUrl.contains('.pdf?') || 
           lowerUrl.contains('/pdf/');
  }

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xFFFFCC00);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: appBarGradient)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              supportZoom: true,
              allowsInlineMediaPlayback: true,
              useShouldOverrideUrlLoading: true, // Required to intercept link clicks
              supportMultipleWindows: true,      // Required to intercept target="_blank"
              useOnDownloadStart: true,          // Required to catch attachment triggers
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
              developer.log("WebView Created");
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (uri != null) {
                final urlString = uri.toString();
                developer.log("Intercepted navigation request => $urlString");
                if (_isPdfUrl(urlString)) {
                  developer.log("PDF link clicked. Launching PdfViewerScreen => $urlString");
                  Get.toNamed('/pdf_viewer', arguments: {'pdfUrl': urlString, 'title': widget.title});
                  return NavigationActionPolicy.CANCEL;
                }
              }
              return NavigationActionPolicy.ALLOW;
            },
            onCreateWindow: (controller, createWindowAction) async {
              final uri = createWindowAction.request.url;
              if (uri != null) {
                final urlString = uri.toString();
                developer.log("Intercepted new window request => $urlString");
                if (_isPdfUrl(urlString)) {
                  developer.log("PDF link clicked in new window. Launching PdfViewerScreen => $urlString");
                  Get.toNamed('/pdf_viewer', arguments: {'pdfUrl': urlString, 'title': widget.title});
                  return true;
                } else {
                  // Load it inside the current WebView instance
                  controller.loadUrl(urlRequest: URLRequest(url: uri));
                  return true;
                }
              }
              return false;
            },
            onDownloadStartRequest: (controller, downloadStartRequest) async {
              final urlString = downloadStartRequest.url.toString();
              developer.log("Intercepted download trigger => $urlString");
              if (_isPdfUrl(urlString)) {
                developer.log("PDF download requested. Launching PdfViewerScreen => $urlString");
                Get.toNamed('/pdf_viewer', arguments: {'pdfUrl': urlString, 'title': widget.title});
              }
            },
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              developer.log("SSL Bypass triggered for host: ${challenge.protectionSpace.host}");
              return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED,
              );
            },
            onLoadStart: (controller, url) {
              developer.log("Load Start => $url");
              setState(() {
                isLoading = true;
              });
            },
            onLoadStop: (controller, url) async {
              developer.log("Load Stop => $url");
              setState(() {
                isLoading = false;
              });
            },
            onProgressChanged: (controller, value) {
              if (!mounted) return;
              setState(() {
                progress = value / 100;
                if (progress >= 1.0) {
                  isLoading = false;
                }
              });
            },
            onReceivedError: (controller, request, error) {
              developer.log("WebView Error => ${error.description}", error: error);
            },
            onReceivedHttpError: (controller, request, errorResponse) {
              developer.log("WebView HTTP Error => ${errorResponse.statusCode}");
            },
            onConsoleMessage: (controller, message) {
              developer.log("WebView Console => ${message.message}");
            },
          ),
          if (isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                minHeight: 3,
                color: brandColor,
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }
}
