import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/sourceforge_auth_service.dart';

class SourceForgeLoginPage extends StatefulWidget {
  const SourceForgeLoginPage({super.key});

  @override
  State<SourceForgeLoginPage> createState() => _SourceForgeLoginPageState();
}

class _SourceForgeLoginPageState extends State<SourceForgeLoginPage> {
  final _auth = SourceForgeAuthService();
  late final WebViewController _controller;
  late final Uri _authorizationUri;
  bool _handled = false;
  bool _loginSubmitted = false;
  bool _resumingAuthorization = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authorizationUri = _auth.createAuthorizationUri();
    _controller = WebViewController()
      ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
          'Mobile/15E148 Safari/604.1')
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          debugPrint('[SourceForgeWebView] page started: $_');
          if (mounted)
            setState(() {
              _loading = true;
              _error = null;
            });
        },
        onPageFinished: (_) {
          debugPrint('[SourceForgeWebView] page finished: $_');
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (error) {
          debugPrint(
              '[SourceForgeWebView] resource error: code=${error.errorCode}, description=${error.description}, mainFrame=${error.isForMainFrame}');
          if (mounted && error.isForMainFrame != false && !_handled) {
            setState(() {
              _loading = false;
              _error = '${error.errorCode}: ${error.description}';
            });
          }
        },
        onNavigationRequest: (request) {
          debugPrint('[SourceForgeWebView] navigation: ${request.url}');
          final uri = Uri.tryParse(request.url);
          if (uri != null &&
              uri.host == 'sourceforge.net' &&
              uri.path == '/auth/do_login') {
            _loginSubmitted = true;
            debugPrint(
                '[SourceForgeWebView] login submitted, waiting for redirect');
          }
          if (uri != null &&
              _loginSubmitted &&
              !_resumingAuthorization &&
              uri.host == 'sourceforge.net' &&
              uri.path == '/') {
            _loginSubmitted = false;
            _resumingAuthorization = true;
            debugPrint(
                '[SourceForgeWebView] login redirected to home, resuming OAuth authorization');
            _controller.loadRequest(_authorizationUri);
            return NavigationDecision.prevent;
          }
          if (uri != null && uri.toString().startsWith(_auth.redirectUri)) {
            _finish(uri);
            // Allow the callback page to finish loading. Preventing it on iOS
            // can abort the main frame and restart the previous OAuth request.
            return NavigationDecision.navigate;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(_authorizationUri);
  }

  Future<void> _finish(Uri uri) async {
    if (_handled) return;
    debugPrint('[SourceForgeWebView] callback intercepted');
    _handled = true;
    try {
      final token = await _auth.exchangeCode(uri);
      debugPrint('[SourceForgeWebView] token exchange completed');
      if (mounted) Navigator.pop(context, token);
    } catch (e) {
      debugPrint('[SourceForgeWebView] OAuth error: $e');
      _handled = false;
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
        debugPrint('[SourceForgeWebView] error state displayed in page');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('SourceForge 登录'),
          actions: [
            IconButton(
              tooltip: '刷新',
              onPressed: () => _controller.reload(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Center(
                child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 42),
                        const SizedBox(height: 12),
                        const Text('SourceForge 页面加载失败'),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _controller.reload(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('重试'),
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
