import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/bot_bloc.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BotBloc, BotState>(
      builder: (context, state) {
        if (state is BotLoaded) {
          return _buildLoadedState(context, state);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildLoadedState(BuildContext context, BotLoaded state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildVersionCard(),
        const SizedBox(height: 24),
        _buildUpdateSection(context, state),
        const SizedBox(height: 24),
        _buildUpdateHistory(state),
        const SizedBox(height: 24),
        _buildLinksSection(context),
      ],
    );
  }

  Widget _buildVersionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.android, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'QQ聊天机器人',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('版本 1.0.0'),
            const SizedBox(height: 8),
            const Text('构建时间: 2024-01-01'),
            const SizedBox(height: 8),
            const Text('最低支持版本: Android 8.0 (API 26)'),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateSection(BuildContext context, BotLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text('版本更新'),
              subtitle: const Text('检查是否有新版本可用'),
              trailing: ElevatedButton(
                onPressed: () {
                  context.read<BotBloc>().add(BotCheckUpdate(isManual: true));
                  Fluttertoast.showToast(msg: '正在检查更新...');
                },
                child: const Text('检查更新'),
              ),
            ),
            const Divider(),
            const ListTile(
              title: Text('当前版本'),
              trailing: Text('1.0.0'),
            ),
            const ListTile(
              title: Text('最新版本'),
              trailing: Text('1.0.0'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateHistory(BotLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '热更新记录',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            state.updates.isEmpty
                ? const Center(
                    child: Text('暂无更新记录'),
                  )
                : Column(
                    children: state.updates.take(10).map((update) {
                      return ListTile(
                        title: Text('版本 ${update.version}'),
                        subtitle: Text(update.updateTime),
                        trailing: update.isForceUpdate
                            ? const Text('强制更新', style: TextStyle(color: Colors.red))
                            : null,
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text('项目仓库'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _launchUrl('https://github.com');
              },
            ),
            ListTile(
              title: const Text('使用帮助'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showHelpDialog(context);
              },
            ),
            ListTile(
              title: const Text('问题反馈'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _launchUrl('https://github.com/issues');
              },
            ),
            ListTile(
              title: const Text('关于作者'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showAboutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Fluttertoast.showToast(msg: '无法打开链接');
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('使用帮助'),
          content: SingleChildScrollView(
            child: Column(
              children: const [
                Text('1. 部署协议端'),
                Text('   - 下载并安装 NapCat 或 Lagrange'),
                Text('   - 配置WebSocket服务端口'),
                SizedBox(height: 12),
                Text('2. 配置连接'),
                Text('   - 在设置页面填写WS地址'),
                Text('   - 格式: ws://IP:端口'),
                SizedBox(height: 12),
                Text('3. 添加规则'),
                Text('   - 在规则管理页面添加回复规则'),
                Text('   - 支持精准/模糊/正则匹配'),
                SizedBox(height: 12),
                Text('4. 启动机器人'),
                Text('   - 返回首页点击启动按钮'),
                Text('   - 检查连接状态是否正常'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('关于作者'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('QQ聊天机器人'),
              SizedBox(height: 8),
              Text('基于 Flutter + Chaquopy 开发'),
              SizedBox(height: 8),
              Text('支持 OneBot v11 协议'),
              SizedBox(height: 8),
              Text('GitHub: https://github.com'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}