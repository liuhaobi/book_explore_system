import 'dart:convert';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class ChatDetailPage extends StatefulWidget {
  final int conversationId;
  final String name;
  final String type;

  const ChatDetailPage({
    super.key,
    required this.conversationId,
    required this.name,
    required this.type,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final ApiClient _api = ApiClient();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api.token = AuthService().token;
    _loadMessages();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final url = '${AppConfig.conversationsUrl}${widget.conversationId}/messages/';
    try {
      final res = await _api.get(url);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> data = body is Map ? (body['results'] ?? []) : body;
        if (mounted) {
          setState(() {
            _messages = data.reversed.toList();
            _loading = false;
          });
          _scrollToBottom();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _inputController.text.trim();
    if (content.isEmpty) return;

    final url = '${AppConfig.conversationsUrl}${widget.conversationId}/send/';
    try {
      final res = await _api.post(url, body: {
        'type': 'text',
        'content': content,
      });
      if (res.statusCode == 201) {
        final body = jsonDecode(res.body);
        if (mounted) {
          _inputController.clear();
          setState(() => _messages.add(body));
          _scrollToBottom();
        }
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_messages.isEmpty) {
      return const Center(child: Text('暂无消息', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageItem(_messages[index]);
      },
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> msg) {
    final isMine = msg['sender']?['username'] == AuthService().currentUser?.username;
    final isRecalled = msg['is_recalled'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) _buildAvatar(msg, isMine),
          if (!isMine) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      msg['sender']?['username'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                if (isRecalled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('消息已撤回', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  )
                else
                  Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMine ? Colors.blue : Colors.grey.shade100,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMine ? 16 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 16),
                      ),
                    ),
                    child: _buildMessageContent(msg, isMine),
                  ),
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 8),
          if (isMine) _buildAvatar(msg, isMine),
        ],
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> msg, bool isMine) {
    final name = msg['sender']?['username'] ?? '?';
    return CircleAvatar(
      radius: 16,
      backgroundColor: isMine ? Colors.blue.shade100 : Colors.grey.shade200,
      child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildMessageContent(Map<String, dynamic> msg, bool isMine) {
    final type = msg['type'] ?? 'text';
    final content = msg['content'] ?? '';

    switch (type) {
      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(content, width: 180, fit: BoxFit.cover),
              ),
          ],
        );
      case 'text':
      default:
        return Text(
          content,
          style: TextStyle(fontSize: 15, color: isMine ? Colors.white : Colors.black87),
        );
    }
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -1))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  hintText: '输入消息...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
