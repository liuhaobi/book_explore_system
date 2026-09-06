import 'dart:convert';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ApiClient _api = ApiClient();
  List<dynamic> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api.token = AuthService().token;
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (_api.token == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _api.get(AppConfig.conversationsUrl);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body is Map ? (body['results'] ?? []) : body;
        if (mounted) {
          setState(() {
            _conversations = data;
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = '加载失败';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '网络错误';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => Navigator.pushNamed(context, '/contacts'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadConversations, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return const Center(
        child: Text('暂无消息', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final conv = _conversations[index];
          return _buildConversationItem(conv);
        },
      ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> conv) {
    final name = conv['display_name'] ?? '未知';
    final avatar = conv['display_avatar'] ?? '';
    final unread = conv['unread_count'] ?? 0;
    final lastMsg = conv['last_message'];
    final lastContent = lastMsg != null
        ? (lastMsg['type'] == 'text' ? lastMsg['content'] ?? '' : '[${_msgTypeLabel(lastMsg['type'])}]')
        : '';
    final lastTime = lastMsg != null ? _formatTime(lastMsg['created_at']) : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: avatar.isNotEmpty
            ? ClipOval(child: Image.network(avatar, width: 40, height: 40, fit: BoxFit.cover))
            : Text(name[0].toUpperCase(), style: TextStyle(color: Colors.blue.shade700)),
      ),
      title: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(lastTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastContent.isEmpty ? '暂无消息' : lastContent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.pushNamed(context, '/chat-detail', arguments: {
          'id': conv['id'],
          'name': conv['display_name'] ?? '',
          'type': conv['type'] ?? 'single',
        });
      },
    );
  }

  String _msgTypeLabel(String type) {
    switch (type) {
      case 'image':
        return '图片';
      case 'voice':
        return '语音';
      case 'video':
        return '视频';
      case 'file':
        return '文件';
      default:
        return '消息';
    }
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      final dt = DateTime.parse(isoTime);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }
}
