import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/home_page.dart';
import 'pages/chat_detail_page.dart';
import 'pages/contacts_page.dart';
import 'pages/friend_requests_page.dart';
import 'pages/profile_page.dart';
import 'pages/change_password_page.dart';
import 'pages/about_page.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pig IM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      home: const SplashPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/home': (context) => const HomePage(),
        '/contacts': (context) => const ContactsPage(),
        '/friend-requests': (context) => const FriendRequestsPage(),
        '/profile': (context) => const ProfilePage(),
        '/change-password': (context) => const ChangePasswordPage(),
        '/about': (context) => const AboutPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              conversationId: args['id'] as int,
              name: args['name'] as String,
              type: args['type'] as String,
            ),
          );
        }
        return null;
      },
    );
  }
}

/// 启动页 - 检查登录状态后跳转
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    try {
      debugPrint('[SplashPage] 开始检查登录状态...');
      await AuthService().init();
      debugPrint('[SplashPage] AuthService.init() 完成, isLoggedIn=${AuthService().isLoggedIn}');

      if (!mounted) {
        debugPrint('[SplashPage] Widget 已卸载，跳过导航');
        return;
      }

      if (AuthService().isLoggedIn) {
        debugPrint('[SplashPage] 已登录，跳转到首页');
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        debugPrint('[SplashPage] 未登录，跳转到登录页');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e, stack) {
      debugPrint('[SplashPage] 检查登录状态出错: $e');
      debugPrint('[SplashPage] 堆栈: $stack');
      if (mounted) {
        debugPrint('[SplashPage] 出错了也跳转到登录页');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Pig IM',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
