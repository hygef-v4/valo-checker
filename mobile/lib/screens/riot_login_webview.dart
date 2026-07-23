import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RiotLoginWebview extends StatefulWidget {
  const RiotLoginWebview({super.key});

  @override
  State<RiotLoginWebview> createState() => _RiotLoginWebviewState();
}

class _RiotLoginWebviewState extends State<RiotLoginWebview> {
  late final WebViewController _controller;
  bool _isLoading = true;

  static const String _riotAuthUrl =
      'https://auth.riotgames.com/authorize?client_id=play-valorant-web-prod&response_type=token%20id_token&redirect_uri=https%3A%2F%2Fplayvalorant.com%2Fopt_in&scope=account%20openid&nonce=1';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _checkUrlForToken(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _checkUrlForToken(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkUrlForToken(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_riotAuthUrl));
  }

  bool _hasPopped = false;

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
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1923),
        elevation: 0,
        title: const Text(
          'ĐĂNG NHẬP RIOT GAMES',
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
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF4655),
              ),
            ),
        ],
      ),
    );
  }
}
