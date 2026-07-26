import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_colors.dart';

/// Riot RSO login flow inside a WebView.
///
/// By default the Riot SSO session cookie is kept, so a returning user whose
/// access token expired is signed back in with one tap instead of retyping
/// credentials. Pass [clearSession] to force a fresh credential prompt
/// (used by "Switch Account").
class RiotLoginWebview extends StatefulWidget {
  final bool clearSession;

  const RiotLoginWebview({super.key, this.clearSession = false});

  @override
  State<RiotLoginWebview> createState() => _RiotLoginWebviewState();
}

class _RiotLoginWebviewState extends State<RiotLoginWebview> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasPopped = false;

  static const String _riotAuthUrl =
      'https://auth.riotgames.com/authorize?client_id=play-valorant-web-prod&response_type=token%20id_token&redirect_uri=https%3A%2F%2Fplayvalorant.com%2Fopt_in&scope=account%20openid&nonce=1';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
            _checkUrlForToken(url);
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _checkUrlForToken(url);
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() {
                _isLoading = false;
                _errorMessage = '${error.description} (${error.errorCode})';
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkUrlForToken(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    if (widget.clearSession) {
      try {
        final cookieManager = WebViewCookieManager();
        await cookieManager.clearCookies();
        await _controller.clearCache();
      } catch (_) {}
    }

    _reloadAuth();
  }

  void _reloadAuth() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _controller.loadRequest(Uri.parse(_riotAuthUrl));
  }

  bool _checkUrlForToken(String url) {
    if (_hasPopped) return true;
    if (url.contains('playvalorant.com/opt_in') && url.contains('access_token')) {
      final accessTokenMatch = RegExp(r'access_token=([^&]+)').firstMatch(url);
      final idTokenMatch = RegExp(r'id_token=([^&]+)').firstMatch(url);

      if (accessTokenMatch != null) {
        _hasPopped = true;
        final accessToken = accessTokenMatch.group(1)!;
        final idToken = idTokenMatch?.group(1) ?? '';

        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop({
            'accessToken': accessToken,
            'idToken': idToken,
          });
        }
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'SIGN IN WITH RIOT GAMES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _reloadAuth,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_errorMessage == null) WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          if (_errorMessage != null && !_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: AppColors.primary, size: 56),
                    const SizedBox(height: 16),
                    const Text(
                      'COULD NOT LOAD LOGIN PAGE',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _reloadAuth,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('RETRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
