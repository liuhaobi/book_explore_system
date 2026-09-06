import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class SourceForgeAuthService {
  String? _verifier;
  String? _state;

  String get redirectUri => AppConfig.sourceForgeCallbackUrl;

  Uri createAuthorizationUri() {
    _verifier = _randomString(64);
    _state = _randomString(32);
    final challenge = base64Url
        .encode(sha256.convert(utf8.encode(_verifier!)).bytes)
        .replaceAll('=', '');
    final uri = Uri.https('sourceforge.net', '/auth/oauth2/authorize', {
      'response_type': 'code',
      'client_id': AppConfig.sourceForgeClientId,
      'redirect_uri': redirectUri,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'state': _state!,
    });
    debugPrint('[SourceForgeAuth] authorization URL: $uri');
    debugPrint(
        '[SourceForgeAuth] stateLength=${_state!.length}, verifierLength=${_verifier!.length}');
    return uri;
  }

  Future<String> exchangeCode(Uri callbackUri) async {
    debugPrint('[SourceForgeAuth] callback received: ${callbackUri.path}');
    final code = callbackUri.queryParameters['code'];
    final state = callbackUri.queryParameters['state'];
    final error = callbackUri.queryParameters['error'];
    if (error != null) {
      debugPrint('[SourceForgeAuth] provider error: $error');
      throw Exception('SourceForge 授权失败：$error');
    }
    if (code == null || _verifier == null || state != _state) {
      debugPrint(
          '[SourceForgeAuth] callback invalid: hasCode=${code != null}, stateMatches=${state == _state}');
      throw Exception('SourceForge 回调参数无效');
    }

    debugPrint('[SourceForgeAuth] sending token exchange request');
    final startedAt = DateTime.now();
    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.sourceForgeTokenUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json'
            },
            body: jsonEncode({
              'code': code,
              'client_id': AppConfig.sourceForgeClientId,
              'code_verifier': _verifier!,
            }),
          )
          .timeout(const Duration(seconds: 20));
      debugPrint(
          '[SourceForgeAuth] token response: status=${response.statusCode}, bodyLength=${response.body.length}, elapsed=${DateTime.now().difference(startedAt).inMilliseconds}ms');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
            '[SourceForgeAuth] token response error: ${response.body.substring(0, response.body.length.clamp(0, 300))}');
        throw Exception('Token 兑换失败 (${response.statusCode})');
      }
      final decoded = jsonDecode(response.body);
      final data = _normalizeTokenResponse(decoded);
      final token = data['access_token'] ?? data['token'];
      if (token is! String || token.isEmpty)
        throw Exception('响应中没有 access_token');
      debugPrint(
          '[SourceForgeAuth] token exchange succeeded, tokenLength=${token.length}');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sourceforge_access_token', token);
      debugPrint('[SourceForgeAuth] access token saved locally');
      return token;
    } on TimeoutException {
      debugPrint('[SourceForgeAuth] token gateway timeout after 20 seconds');
      throw Exception('Token 兑换超时，请稍后重试');
    } catch (e) {
      debugPrint('[SourceForgeAuth] token exchange exception: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _normalizeTokenResponse(Object? decoded) {
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    if (decoded is String) {
      final value = decoded.trim();
      try {
        final nested = jsonDecode(value);
        if (nested is Map) return Map<String, dynamic>.from(nested);
      } on FormatException {
        // Continue with form-encoded/plain-token handling below.
      }
      final form = Uri.splitQueryString(value);
      if (form.containsKey('access_token') || form.containsKey('token')) {
        return form;
      }
      if (value == '授权成功' || value == 'Authorization completed') {
        throw Exception('Token 接口返回了授权成功提示，但没有返回 access_token');
      }
      if (value.isNotEmpty) return {'access_token': value};
    }
    throw Exception('Token 响应格式无效');
  }

  String _randomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }
}
