import 'dart:convert';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  final ApiClient _api = ApiClient();
  List<dynamic> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api.token = AuthService().token;
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get(AppConfig.friendRequestsUrl);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted) setState(() {
          _requests = data.where((r) => r['status'] == 'pending').toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleRequest(int id, String action) async {
    try {
      final res = await _api.post('${AppConfig.friendRequestsUrl}$id/action/', body: {
        'action': action,
      });
      if (res.statusCode == 200) {
        _loadRequests();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('好友请求')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_disabled, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('暂无好友请求', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final req = _requests[index];
          final fromUser = req['from_user'] ?? {};
          final message = req['message'] ?? '';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        radius: 22,
                        child: Text(
                          (fromUser['username'] as String? ?? '?')[0].toUpperCase(),
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fromUser['username'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            if (message.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => _handleRequest(req['id'], 'reject'),
                        child: const Text('拒绝'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _handleRequest(req['id'], 'accept'),
                        child: const Text('接受'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
