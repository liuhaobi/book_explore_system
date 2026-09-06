import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'sourceforge_login_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loggingIn = false;

  Future<void> _loginWithSourceForge(BuildContext context) async {
    if (_loggingIn) return;
    setState(() => _loggingIn = true);
    try {
      final token = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const SourceForgeLoginPage()),
      );
      if (!context.mounted || token == null) return;
      await AuthService().loginWithSourceForgeToken(token);
      if (!context.mounted) return;
      debugPrint('[LoginPage] SourceForge login completed, opening home');
      Navigator.of(context).pushReplacementNamed('/home');
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed:
                    _loggingIn ? null : () => _loginWithSourceForge(context),
                icon: const Icon(Icons.code),
                label: Text(_loggingIn ? '正在登录...' : '使用 SourceForge 登录'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
