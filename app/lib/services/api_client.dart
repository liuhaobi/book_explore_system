import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  String? token;
  static const _tag = '[ApiClient]';

  // ---------- 通用请求头 ----------
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      };

  // ---------- GET ----------
  Future<http.Response> get(String url) async {
    debugPrint('$_tag GET $url');
    final start = DateTime.now();
    try {
      final res = await http.get(Uri.parse(url), headers: _headers);
      _logResponse('GET', url, start, res);
      return res;
    } catch (e, stack) {
      _logError('GET', url, start, e, stack);
      rethrow;
    }
  }

  // ---------- POST ----------
  Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    debugPrint('$_tag POST $url');
    if (body != null) {
      debugPrint('$_tag body: ${jsonEncode(body)}');
    }
    final start = DateTime.now();
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      _logResponse('POST', url, start, res);
      return res;
    } catch (e, stack) {
      _logError('POST', url, start, e, stack);
      rethrow;
    }
  }

  // ---------- PUT ----------
  Future<http.Response> put(String url, {Map<String, dynamic>? body}) async {
    debugPrint('$_tag PUT $url');
    if (body != null) {
      debugPrint('$_tag body: ${jsonEncode(body)}');
    }
    final start = DateTime.now();
    try {
      final res = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      _logResponse('PUT', url, start, res);
      return res;
    } catch (e, stack) {
      _logError('PUT', url, start, e, stack);
      rethrow;
    }
  }

  // ---------- DELETE ----------
  Future<http.Response> delete(String url) async {
    debugPrint('$_tag DELETE $url');
    final start = DateTime.now();
    try {
      final res = await http.delete(Uri.parse(url), headers: _headers);
      _logResponse('DELETE', url, start, res);
      return res;
    } catch (e, stack) {
      _logError('DELETE', url, start, e, stack);
      rethrow;
    }
  }

  // ---------- 日志 ----------
  void _logResponse(String method, String url, DateTime start, http.Response res) {
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    debugPrint('$_tag $method $url → ${res.statusCode} (${elapsed}ms)');
    if (res.body.isNotEmpty && res.body.length < 1500) {
      debugPrint('$_tag response: ${res.body}');
    } else if (res.body.isNotEmpty) {
      debugPrint('$_tag response: ${res.body.substring(0, 400)}...(truncated)');
    }
  }

  void _logError(String method, String url, DateTime start, Object e, StackTrace stack) {
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    debugPrint('$_tag $method $url → ERROR after ${elapsed}ms');
    debugPrint('$_tag error: $e');
    debugPrint('$_tag stack: $stack');
  }
}
