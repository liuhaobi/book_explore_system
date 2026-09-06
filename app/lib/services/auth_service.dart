import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/user.dart';
import '../services/api_client.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _api = ApiClient();

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null;
  String? _token;
  User? _currentUser;

  Future<void> init() async {
    debugPrint('[AuthService] init() 开始...');
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token') ??
          prefs.getString('sourceforge_access_token');
      _api.token = _token;
      debugPrint('[AuthService] token=${_token != null ? "存在" : "不存在"}');
      final userJson = prefs.getString('user_info');
      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
        debugPrint('[AuthService] 用户信息已加载: ${_currentUser?.username}');
      }
      notifyListeners();
      debugPrint('[AuthService] init() 完成');
    } catch (e, stack) {
      debugPrint('[AuthService] init() 出错: $e');
      debugPrint('[AuthService] 堆栈: $stack');
    }
  }

  /// 保存 SourceForge OAuth 登录状态。
  ///
  /// SourceForge 登录返回的 token 也需要接入应用统一的登录状态，
  /// 否则登录页虽然能跳转，启动页仍会认为用户未登录。
  Future<void> loginWithSourceForgeToken(String token) async {
    _token = token;
    _api.token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sourceforge_access_token', token);
    await prefs.setString('auth_token', token);
    notifyListeners();
    debugPrint('[AuthService] SourceForge token 已保存，登录状态已更新');
  }

  /// 刷新当前用户信息（从服务器拉取）
  Future<void> refreshUser() async {
    try {
      final res = await _api.get(AppConfig.profileUrl);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _currentUser = User.fromJson(data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_info', jsonEncode(_currentUser!.toJson()));
        notifyListeners();
        debugPrint('[AuthService] 用户信息已刷新: ${_currentUser?.username}');
      }
    } catch (e) {
      debugPrint('[AuthService] 刷新用户信息失败: $e');
    }
  }

  /// 用户登录
  Future<AuthResult> login(String username, String password) async {
    try {
      final res = await _api.post(AppConfig.loginUrl, body: {
        'username': username,
        'password': password,
      });

      try {
        final data = jsonDecode(res.body);
        if (res.statusCode == 200) {
          _token = data['token'];
          _api.token = _token;
          _currentUser = User.fromJson(data['user']);
          await _saveLoginState();
          notifyListeners();
          return AuthResult(success: true, message: data['message'] ?? '登录成功');
        }
        return AuthResult(success: false, message: data['error'] ?? '登录失败');
      } on FormatException {
        debugPrint('[AuthService] 响应为非JSON: ${res.body.substring(0, 200)}');
        return AuthResult(
          success: false,
          message: '服务器错误 (${res.statusCode})',
        );
      }
    } catch (e) {
      return AuthResult(success: false, message: '网络错误，请稍后重试');
    }
  }

  /// 用户注册
  Future<AuthResult> register({
    required String username,
    required String password,
    required String passwordConfirm,
    String email = '',
  }) async {
    try {
      final res = await _api.post(AppConfig.registerUrl, body: {
        'username': username,
        'password': password,
        'password_confirm': passwordConfirm,
        'email': email,
      });

      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        _token = data['token'];
        _api.token = _token;
        _currentUser = User.fromJson(data['user']);
        await _saveLoginState();
        notifyListeners();
        return AuthResult(success: true, message: data['message'] ?? '注册成功');
      }
      if (data is Map) {
        final errors = <String>[];
        data.forEach((key, value) {
          if (value is List) {
            errors.addAll(value.map((e) => e.toString()));
          } else if (value is String) {
            errors.add(value);
          }
        });
        return AuthResult(
          success: false,
          message: errors.isNotEmpty ? errors.join('\n') : '注册失败',
        );
      }
      return AuthResult(success: false, message: '注册失败');
    } catch (e) {
      return AuthResult(success: false, message: '网络错误，请稍后重试');
    }
  }

  /// 忘记密码 - 验证用户身份
  Future<AuthResult> forgotPassword(String username) async {
    try {
      final res = await _api.post(AppConfig.forgotPasswordUrl, body: {
        'username': username,
      });
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return AuthResult(success: true, message: data['message'] ?? '验证成功');
      }
      return AuthResult(success: false, message: data['error'] ?? '用户不存在');
    } catch (e) {
      return AuthResult(success: false, message: '网络错误，请稍后重试');
    }
  }

  /// 重置密码（忘记密码后）
  Future<AuthResult> resetPassword({
    required String username,
    required String newPassword,
  }) async {
    try {
      final res = await _api.post(AppConfig.resetPasswordUrl, body: {
        'username': username,
        'new_password': newPassword,
      });
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return AuthResult(success: true, message: data['message'] ?? '密码重置成功');
      }
      return AuthResult(success: false, message: data['error'] ?? '重置失败');
    } catch (e) {
      return AuthResult(success: false, message: '网络错误，请稍后重试');
    }
  }

  /// 修改密码（已登录）
  Future<AuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final res = await _api.post(AppConfig.changePasswordUrl, body: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return AuthResult(success: true, message: data['message'] ?? '密码修改成功');
      }
      return AuthResult(success: false, message: data['error'] ?? '修改失败');
    } catch (e) {
      return AuthResult(success: false, message: '网络错误，请稍后重试');
    }
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      await _api.post(AppConfig.logoutUrl);
    } catch (_) {}
    _token = null;
    _api.token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('sourceforge_access_token');
    await prefs.remove('user_info');
    notifyListeners();
  }

  Future<void> _saveLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString('auth_token', _token!);
    }
    if (_currentUser != null) {
      await prefs.setString('user_info', jsonEncode(_currentUser!.toJson()));
    }
  }
}

class AuthResult {
  final bool success;
  final String message;

  AuthResult({required this.success, required this.message});
}
