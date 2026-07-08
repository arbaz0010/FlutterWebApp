import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewerController extends GetxController {
  final String url;
  late final WebViewController webViewController;

  RxInt loadingPercentage = RxInt(0);
  RxBool hasInternetConnection = RxBool(false);

  WebViewerController(this.url);

  @override
  void onInit() {
    initializeWebView();
    super.onInit();
  }

  void initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Forces YouTube to treat the app like a standard mobile browser so it stays inside
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) async {
          final currentUrl = request.url;

          // 1. Keep all YouTube internal links (homepage, videos, shorts, channels) inside the app
          if (currentUrl.contains('youtube.com') || currentUrl.contains('youtu.be')) {
            return NavigationDecision.navigate;
          }

          // 2. Keep your specific base URL or deep links inside the app
          if (currentUrl.startsWith(url)) {
            return NavigationDecision.navigate;
          }

          // 3. Open completely external websites (like Facebook, Instagram, Twitter) in external browser
          await launchExternalUrl(currentUrl);
          return NavigationDecision.prevent;
        },
        onProgress: (progress) => loadingPercentage.value = progress,
        onPageFinished: (_) => hasInternetConnection.value = true,
        onWebResourceError: (error) {
          if (error.errorType == WebResourceErrorType.hostLookup ||
              error.errorType == WebResourceErrorType.connect) {
            hasInternetConnection.value = false;
            loadingPercentage.value = 0;
          }
        },
      ))
      ..loadRequest(Uri.parse(url));
  }

  // Retry reload if there was an error
  Future<void> retryConnection() async {
    hasInternetConnection.value = true;
    loadingPercentage.value = 0;
    webViewController.reload();
  }

  // Launch external links via default browser
  Future<void> launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Unable to handle your request');
    }
  }

  // Navigation helpers for back functionality
  Future<bool> canGoBack() async => await webViewController.canGoBack();

  void goBack() => webViewController.goBack();
} 
