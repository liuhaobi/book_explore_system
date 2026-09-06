import 'dart:convert';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;

  // 好友列表
  List<dynamic> _friends = [];
  bool _friendsLoading = true;

  // 搜索
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _api.token = AuthService().token;
    _tabController = TabController(length: 2, vsync: this);
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _friendsLoading = true);
    try {
      final res = await _api.get(AppConfig.friendsUrl);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted) setState(() {
          _friends = data;
          _friendsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _friendsLoading = false);
    }
  }

  Future<void> _search() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    setState(() => _searching = true);
    try {
      final res = await _api.get('${AppConfig.friendSearchUrl}?keyword=$keyword');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted) setState(() {
          _searchResults = data;
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _addFriend(int userId) async {
    try {
      final res = await _api.post(AppConfig.friendRequestsUrl, body: {
        'to_user_id': userId,
        'message': '你好，我想加你为好友',
      });

      final body = jsonDecode(res.body);
      if (mounted) {
        final msg = res.statusCode == 201 ? '好友请求已发送' : (body['error'] ?? '操作失败');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('网络错误')));
      }
    }
  }

  Future<void> _deleteFriend(int userId, String username) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除好友'),
        content: Text('确定要删除好友 $username 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.delete('${AppConfig.friendsUrl}$userId/');
                _loadFriends();
              } catch (_) {}
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通讯录'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '好友'),
            Tab(text: '添加'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendList(),
          _buildSearchTab(),
        ],
      ),
    );
  }

  Widget _buildFriendList() {
    if (_friendsLoading) return const Center(child: CircularProgressIndicator());

    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('暂无好友', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextButton(onPressed: () => _tabController.animateTo(1), child: const Text('去添加好友')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: ListView.separated(
        itemCount: _friends.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                (friend['username'] as String? ?? '?')[0].toUpperCase(),
                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500),
              ),
            ),
            title: Text(friend['username'] ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () => _deleteFriend(friend['id'], friend['username'] ?? ''),
            ),
            onTap: () {
              // 创建或进入单聊
              _createSingleChat(friend['id']);
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索用户名',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () { _searchController.clear(); setState(() {}); },
              )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (_searching)
          const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
        else if (_searchResults.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      (user['username'] as String? ?? '?')[0].toUpperCase(),
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                  title: Text(user['username'] ?? ''),
                  trailing: FilledButton.tonalIcon(
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('添加'),
                    onPressed: () => _addFriend(user['id']),
                  ),
                );
              },
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Text('输入用户名搜索', style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }

  Future<void> _createSingleChat(int userId) async {
    try {
      final res = await _api.post(AppConfig.conversationsUrl, body: {
        'type': 'single',
        'user_id': userId,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        final id = body['id'];
        final name = body['display_name'] ?? '';
        if (mounted) {
          Navigator.pushNamed(context, '/chat-detail', arguments: {
            'id': id,
            'name': name,
            'type': 'single',
          });
        }
      }
    } catch (_) {}
  }
}
