import 'dart:convert';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;

  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();

  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _api.token = AuthService().token;
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final resProfile = await _api.get(AppConfig.profileUrl);
      final resDetail = await _api.get('${AppConfig.profileUrl}detail/');
      if (mounted) {
        if (resProfile.statusCode == 200) {
          final data = jsonDecode(resProfile.body);
          _usernameCtrl.text = data['username'] ?? '';
          _emailCtrl.text = data['email'] ?? '';
          _firstNameCtrl.text = data['first_name'] ?? '';
          _lastNameCtrl.text = data['last_name'] ?? '';
        }
        if (resDetail.statusCode == 200) {
          final detail = jsonDecode(resDetail.body);
          _phoneCtrl.text = detail['phone'] ?? '';
          _bioCtrl.text = detail['bio'] ?? '';
          _avatarUrl = (detail['avatar'] ?? '').toString();
          _avatarCtrl.text = _avatarUrl ?? '';
        }
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await _api.put(AppConfig.profileUrl, body: {
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
      });

      await _api.put('${AppConfig.profileUrl}detail/', body: {
        'phone': _phoneCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'avatar': _avatarCtrl.text.trim(),
      });

      // 同时更新本地头像显示
      setState(() {
        _avatarUrl = _avatarCtrl.text.trim();
      });

      await AuthService().refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网络错误'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildAvatar() {
    final hasAvatar = _avatarUrl != null && _avatarUrl!.isNotEmpty;
    return GestureDetector(
      onTap: () => _showAvatarDialog(),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: hasAvatar ? NetworkImage(_avatarUrl!) : null,
            onBackgroundImageError: hasAvatar ? (_, __) {
              setState(() => _avatarUrl = null);
            } : null,
            child: hasAvatar
                ? null
                : Text(
                    _usernameCtrl.text.isNotEmpty ? _usernameCtrl.text[0].toUpperCase() : 'U',
                    style: TextStyle(fontSize: 40, color: Colors.grey.shade500),
                  ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置头像'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入头像图片的URL地址：'),
            const SizedBox(height: 12),
            TextField(
              controller: _avatarCtrl,
              decoration: const InputDecoration(
                hintText: 'https://example.com/avatar.jpg',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_avatarCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _avatarCtrl.text.trim(),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              setState(() {
                _avatarUrl = _avatarCtrl.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人信息'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('保存'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 头像区域
                    _buildAvatar(),
                    const SizedBox(height: 28),

                    // 基本信息
                    _buildSectionTitle('基本信息'),
                    const SizedBox(height: 12),
                    _buildField('用户名', _usernameCtrl, icon: Icons.person_outline),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _buildField('姓', _lastNameCtrl, icon: Icons.badge_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField('名', _firstNameCtrl, icon: Icons.badge_outlined)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildField('邮箱', _emailCtrl, icon: Icons.email_outlined, inputType: TextInputType.emailAddress),

                    const SizedBox(height: 28),
                    _buildSectionTitle('联系方式'),
                    const SizedBox(height: 12),
                    _buildField('手机号', _phoneCtrl, icon: Icons.phone_outlined, inputType: TextInputType.phone),

                    const SizedBox(height: 28),
                    _buildSectionTitle('个人简介'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioCtrl,
                      decoration: const InputDecoration(
                        hintText: '介绍一下自己...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      maxLength: 500,
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check),
                        label: Text(_saving ? '保存中...' : '保存修改', style: const TextStyle(fontSize: 16)),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {
    IconData? icon,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      keyboardType: inputType,
      validator: validator ?? (v) => v != null && v.trim().isEmpty ? '$label不能为空' : null,
    );
  }
}
