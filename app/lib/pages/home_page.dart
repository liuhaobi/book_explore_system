import 'package:flutter/material.dart';

import 'mine_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: const [_SourceForgeDashboard(), MinePage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (value) => setState(() => _tabIndex = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '项目',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class _SourceForgeDashboard extends StatelessWidget {
  const _SourceForgeDashboard();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: const Color(0xFF253746),
          foregroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.terminal_rounded, color: Color(0xFFF47B20)),
              SizedBox(width: 9),
              Text('SourceForge',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ProjectCard(),
                const SizedBox(height: 24),
                const Text('项目概览',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                        child: _StatCard(
                            value: '3',
                            label: '代码仓库',
                            icon: Icons.account_tree_outlined,
                            color: Color(0xFF3B82F6))),
                    SizedBox(width: 12),
                    Expanded(
                        child: _StatCard(
                            value: '18',
                            label: '开放 Issue',
                            icon: Icons.confirmation_number_outlined,
                            color: Color(0xFFF59E0B))),
                    SizedBox(width: 12),
                    Expanded(
                        child: _StatCard(
                            value: '6',
                            label: '贡献者',
                            icon: Icons.people_outline,
                            color: Color(0xFF22A06B))),
                  ],
                ),
                const SizedBox(height: 26),
                const _SectionHeader(title: '代码仓库', action: '查看全部'),
                const SizedBox(height: 10),
                const _RepositoryCard(
                    name: 'sourceforge-mobile',
                    language: 'Dart',
                    languageColor: Color(0xFF00B4AB),
                    branch: 'main',
                    updated: '刚刚更新'),
                const SizedBox(height: 10),
                const _RepositoryCard(
                    name: 'sourceforge-api',
                    language: 'Python',
                    languageColor: Color(0xFF3776AB),
                    branch: 'main',
                    updated: '2 小时前更新'),
                const SizedBox(height: 26),
                const _SectionHeader(title: '最新提交', action: '提交历史'),
                const _ActivityTile(
                    avatar: 'LH',
                    title: '优化 OAuth 登录回调流程',
                    subtitle: 'liuhaobi · sourceforge-mobile',
                    meta: 'a1b2c3d · 12 分钟前'),
                const _ActivityTile(
                    avatar: 'SF',
                    title: '更新 API Token 代理配置',
                    subtitle: 'source3 · sourceforge-api',
                    meta: 'd4e5f6a · 2 小时前'),
                const SizedBox(height: 26),
                const _SectionHeader(title: '待处理 Issue', action: '全部 Issue'),
                const SizedBox(height: 8),
                const _IssueTile(
                    number: 24,
                    title: 'iOS WebView 授权后应自动返回应用',
                    status: 'Open',
                    color: Color(0xFFF59E0B)),
                const _IssueTile(
                    number: 21,
                    title: '增加项目仓库和提交列表接口',
                    status: 'In progress',
                    color: Color(0xFF3B82F6)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF253746), Color(0xFF3B5364)]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.folder_copy_outlined, color: Color(0xFFF47B20)),
              SizedBox(width: 8),
              Text('项目空间', style: TextStyle(color: Color(0xFFB8C8D3)))
            ]),
            SizedBox(height: 14),
            Text('SourceForge Mobile',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 7),
            Text('移动端 OAuth 与项目协作工作台',
                style: TextStyle(color: Color(0xFFD7E2E8))),
            SizedBox(height: 16),
            Row(children: [
              Icon(Icons.public, size: 17, color: Color(0xFFB8C8D3)),
              SizedBox(width: 5),
              Text('公开项目', style: TextStyle(color: Color(0xFFB8C8D3)))
            ])
          ],
        ),
      );
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12)),
        child: Column(children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey))
        ]),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  const _SectionHeader({required this.title, required this.action});

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton(onPressed: () {}, child: Text(action))
      ]);
}

class _RepositoryCard extends StatelessWidget {
  final String name;
  final String language;
  final Color languageColor;
  final String branch;
  final String updated;
  const _RepositoryCard(
      {required this.name,
      required this.language,
      required this.languageColor,
      required this.branch,
      required this.updated});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE1E7EB))),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.account_tree_outlined, color: Color(0xFF536878)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              const Icon(Icons.chevron_right, color: Colors.grey)
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                      color: languageColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(language),
              const SizedBox(width: 16),
              const Icon(Icons.call_split, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(branch),
              const Spacer(),
              Text(updated,
                  style: const TextStyle(fontSize: 12, color: Colors.grey))
            ]),
          ]),
        ),
      );
}

class _ActivityTile extends StatelessWidget {
  final String avatar;
  final String title;
  final String subtitle;
  final String meta;
  const _ActivityTile(
      {required this.avatar,
      required this.title,
      required this.subtitle,
      required this.meta});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        leading: CircleAvatar(
            backgroundColor: const Color(0xFFE6EEF2),
            foregroundColor: const Color(0xFF253746),
            child: Text(avatar,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold))),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(subtitle),
          const SizedBox(height: 3),
          Text(meta, style: const TextStyle(fontSize: 12, color: Colors.grey))
        ]),
      );
}

class _IssueTile extends StatelessWidget {
  final int number;
  final String title;
  final String status;
  final Color color;
  const _IssueTile(
      {required this.number,
      required this.title,
      required this.status,
      required this.color});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 9),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE1E7EB))),
        child: ListTile(
          leading: Icon(Icons.confirmation_number_outlined, color: color),
          title: Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text('#$number · $status'),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
}
