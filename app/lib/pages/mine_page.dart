import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  @override
  void initState() {
    super.initState();
    // 每次进入页面时刷新用户信息
    AuthService().refreshUser();
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        final user = AuthService().currentUser;
        final hasAvatar = user?.avatar.isNotEmpty == true;

        return Scaffold(
          appBar: AppBar(title: const Text('我的')),
          body: ListView(
            children: [
              // 用户信息卡片
              Container(
                padding: const EdgeInsets.all(24),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      // 头像
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage:
                            hasAvatar ? NetworkImage(user!.avatar) : null,
                        onBackgroundImageError: hasAvatar ? (_, __) {} : null,
                        child: hasAvatar
                            ? null
                            : Text(
                                user?.username.isNotEmpty == true
                                    ? user!.username[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                    fontSize: 28, color: Colors.white),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.username ?? '未登录',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            if (user?.email.isNotEmpty == true)
                              _buildInfoRow(Icons.email_outlined, user!.email),
                            if (user?.phone.isNotEmpty == true)
                              _buildInfoRow(Icons.phone_outlined, user!.phone),
                            if (user?.email.isEmpty == true &&
                                user?.phone.isEmpty == true)
                              Text(
                                '点击完善个人信息',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 菜单项 - 分组
              _buildSectionTitle('社交'),
              _buildMenuItem(
                icon: Icons.contacts_outlined,
                title: '通讯录',
                onTap: () => Navigator.pushNamed(context, '/contacts'),
              ),
              _buildMenuItem(
                icon: Icons.person_add_outlined,
                title: '好友请求',
                onTap: () => Navigator.pushNamed(context, '/friend-requests'),
              ),

              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildSectionTitle('设置'),
              _buildMenuItem(
                icon: Icons.person_outline,
                title: '个人信息',
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
              _buildMenuItem(
                icon: Icons.lock_outline,
                title: '修改密码',
                onTap: () => Navigator.pushNamed(context, '/change-password'),
              ),
              _buildMenuItem(
                icon: Icons.info_outline,
                title: '关于',
                onTap: () => Navigator.pushNamed(context, '/about'),
              ),

              const SizedBox(height: 24),

              // 退出登录
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.exit_to_app, color: Colors.red),
                  label:
                      const Text('退出登录', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Pig IM v1.0.0',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
