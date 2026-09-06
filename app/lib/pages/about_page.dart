import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.chat, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pig IM',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'v1.0.0',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // 描述
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text(
                    '一款基于 Flutter + Django 的即时通讯应用，支持单聊、群聊、好友管理等功能。',
                    style: TextStyle(fontSize: 14, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '技术栈：Flutter · Django · Django REST Framework · Django Channels',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 功能列表
            _buildFeatureItem(context, Icons.chat_bubble_outline, '即时通讯', '支持文字、图片消息的发送与接收'),
            _buildFeatureItem(context, Icons.people_outline, '好友管理', '搜索用户、添加好友、管理好友请求'),
            _buildFeatureItem(context, Icons.person_outline, '个人中心', '管理个人信息、头像、密码等'),

            const SizedBox(height: 48),
            Text(
              'Copyright 2026 Pig IM Team',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 8),
            Text(
              'All Rights Reserved',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String desc) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 13)),
      contentPadding: EdgeInsets.zero,
    );
  }
}
