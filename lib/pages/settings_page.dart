import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../bloc/bot_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _wsUrlController;
  late TextEditingController _portController;
  late TextEditingController _accessTokenController;
  late TextEditingController _qqIdController;
  late TextEditingController _reconnectIntervalController;
  late TextEditingController _maxReconnectAttemptsController;
  late TextEditingController _updateSourceController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<BotBloc>().state;
    if (state is BotLoaded) {
      _wsUrlController = TextEditingController(text: state.config.wsUrl);
      _portController = TextEditingController(text: state.config.port.toString());
      _accessTokenController = TextEditingController(text: state.config.accessToken);
      _qqIdController = TextEditingController(text: state.config.qqId);
      _reconnectIntervalController = TextEditingController(text: state.config.reconnectInterval.toString());
      _maxReconnectAttemptsController = TextEditingController(text: state.config.maxReconnectAttempts.toString());
      _updateSourceController = TextEditingController(text: state.config.updateSource);
    }
  }

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
        _buildSectionTitle('基础连接配置'),
        _buildConnectionSettings(state),
        const SizedBox(height: 24),
        _buildSectionTitle('机器人基础设置'),
        _buildBotSettings(state),
        const SizedBox(height: 24),
        _buildSectionTitle('热更新设置'),
        _buildUpdateSettings(state),
        const SizedBox(height: 24),
        _buildSectionTitle('系统设置'),
        _buildSystemSettings(state),
        const SizedBox(height: 24),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }

  Widget _buildConnectionSettings(BotLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _wsUrlController,
              decoration: const InputDecoration(labelText: 'WS地址'),
            ),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(labelText: '端口'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _accessTokenController,
              decoration: const InputDecoration(labelText: 'Access Token'),
            ),
            TextFormField(
              controller: _qqIdController,
              decoration: const InputDecoration(labelText: 'QQ号'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotSettings(BotLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('自动重连'),
              value: state.config.autoReconnect,
              onChanged: (value) {
                _updateConfig(state, autoReconnect: value);
              },
            ),
            TextFormField(
              controller: _reconnectIntervalController,
              decoration: const InputDecoration(labelText: '重连间隔(秒)'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _maxReconnectAttemptsController,
              decoration: const InputDecoration(labelText: '最大重连次数'),
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              title: const Text('全局回复'),
              value: state.config.globalReplyEnabled,
              onChanged: (value) {
                _updateConfig(state, globalReplyEnabled: value);
              },
            ),
            SwitchListTile(
              title: const Text('私聊回复'),
              value: state.config.privateEnabled,
              onChanged: (value) {
                _updateConfig(state, privateEnabled: value);
              },
            ),
            SwitchListTile(
              title: const Text('群聊回复'),
              value: state.config.groupEnabled,
              onChanged: (value) {
                _updateConfig(state, groupEnabled: value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateSettings(BotLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('自动检测更新'),
              value: state.config.autoUpdateEnabled,
              onChanged: (value) {
                _updateConfig(state, autoUpdateEnabled: value);
              },
            ),
            TextFormField(
              controller: _updateSourceController,
              decoration: const InputDecoration(labelText: '更新源地址'),
            ),
            ListTile(
              title: const Text('手动检查更新'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                context.read<BotBloc>().add(BotCheckUpdate(isManual: true));
                Fluttertoast.showToast(msg: '正在检查更新...');
              },
            ),
            ListTile(
              title: const Text('更新历史记录'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Fluttertoast.showToast(msg: '更新历史功能开发中');
              },
            ),
            ListTile(
              title: const Text('脚本回滚'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Fluttertoast.showToast(msg: '脚本回滚功能开发中');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSettings(BotLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('前台服务'),
              subtitle: const Text('开启后APP在后台保活'),
              value: state.config.foregroundServiceEnabled,
              onChanged: (value) {
                _updateConfig(state, foregroundServiceEnabled: value);
              },
            ),
            ListTile(
              title: const Text('配置备份'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Fluttertoast.showToast(msg: '配置备份功能开发中');
              },
            ),
            ListTile(
              title: const Text('配置恢复'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Fluttertoast.showToast(msg: '配置恢复功能开发中');
              },
            ),
            ListTile(
              title: const Text('清除缓存'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('确认清除'),
                      content: const Text('确定要清除缓存吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Fluttertoast.showToast(msg: '缓存已清除');
                          },
                          child: const Text('确定', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              title: const Text('新手引导'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showGuideDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _saveSettings(context);
            },
            child: const Text('保存配置'),
          ),
        ),
      ],
    );
  }

  void _updateConfig(BotLoaded state, {
    bool? autoReconnect,
    bool? globalReplyEnabled,
    bool? privateEnabled,
    bool? groupEnabled,
    bool? autoUpdateEnabled,
    bool? foregroundServiceEnabled,
  }) {
    final newConfig = state.config.copyWith(
      autoReconnect: autoReconnect ?? state.config.autoReconnect,
      globalReplyEnabled: globalReplyEnabled ?? state.config.globalReplyEnabled,
      privateEnabled: privateEnabled ?? state.config.privateEnabled,
      groupEnabled: groupEnabled ?? state.config.groupEnabled,
      autoUpdateEnabled: autoUpdateEnabled ?? state.config.autoUpdateEnabled,
      foregroundServiceEnabled: foregroundServiceEnabled ?? state.config.foregroundServiceEnabled,
    );
    context.read<BotBloc>().add(BotUpdateConfig(config: newConfig));
  }

  void _saveSettings(BuildContext context) {
    final state = context.read<BotBloc>().state;
    if (state is BotLoaded) {
      final newConfig = BotConfig(
        wsUrl: _wsUrlController.text,
        port: int.tryParse(_portController.text) ?? 8080,
        accessToken: _accessTokenController.text,
        qqId: _qqIdController.text,
        autoReconnect: state.config.autoReconnect,
        reconnectInterval: int.tryParse(_reconnectIntervalController.text) ?? 5,
        maxReconnectAttempts: int.tryParse(_maxReconnectAttemptsController.text) ?? 10,
        globalReplyEnabled: state.config.globalReplyEnabled,
        privateEnabled: state.config.privateEnabled,
        groupEnabled: state.config.groupEnabled,
        autoUpdateEnabled: state.config.autoUpdateEnabled,
        updateSource: _updateSourceController.text,
        foregroundServiceEnabled: state.config.foregroundServiceEnabled,
      );
      context.read<BotBloc>().add(BotUpdateConfig(config: newConfig));
      Fluttertoast.showToast(msg: '配置已保存');
    }
  }

  void _showGuideDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新手引导'),
          content: SingleChildScrollView(
            child: Column(
              children: const [
                Text('1. 部署协议端'),
                Text('   - 推荐使用 NapCat 或 Lagrange'),
                Text('   - 配置WebSocket服务'),
                SizedBox(height: 12),
                Text('2. 配置连接参数'),
                Text('   - 在设置页面填写WS地址'),
                Text('   - 填写Access Token（如需要）'),
                SizedBox(height: 12),
                Text('3. 添加回复规则'),
                Text('   - 在规则管理页面添加规则'),
                Text('   - 设置关键词和回复内容'),
                SizedBox(height: 12),
                Text('4. 启动机器人'),
                Text('   - 返回首页点击启动按钮'),
                Text('   - 检查连接状态'),
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
}