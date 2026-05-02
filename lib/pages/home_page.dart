import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/bot_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BotBloc, BotState>(
      listener: (context, state) {
        if (state is BotLoaded && state.errorMessage.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
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
        if (state.errorMessage.isNotEmpty)
          _buildErrorBanner(state.errorMessage),
        _buildStatusCard(state),
        const SizedBox(height: 16),
        _buildControlButtons(context, state),
        const SizedBox(height: 16),
        _buildStatsCard(state),
        const SizedBox(height: 16),
        _buildQuickActions(context),
      ],
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '连接失败',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                Text(error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BotLoaded state) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '机器人状态',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getStatusColor(state.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusText(state.status),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(state.status),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'QQ号: ${state.qqId.isNotEmpty ? state.qqId : '未连接'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.network_check, size: 20),
                const SizedBox(width: 8),
                Text(
                  'WS连接状态: ${_getWSStatusText(state.wsStatus)}',
                  style: TextStyle(
                    color: _getWSStatusColor(state.wsStatus),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context, BotLoaded state) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: state.status == BotStatus.running ? null : () {
              context.read<BotBloc>().add(BotStart());
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '启动机器人',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: state.status != BotStatus.running ? null : () {
              context.read<BotBloc>().add(BotStop());
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '停止机器人',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BotLoaded state) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '快捷数据',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 2,
              children: [
                _buildStatItem('今日接收', state.stats.receivedMessages.toString()),
                _buildStatItem('触发回复', state.stats.repliedMessages.toString()),
                _buildStatItem('运行时长', _formatDuration(state.stats.runningTime)),
                _buildStatItem('重连次数', state.stats.reconnectCount.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '快捷操作',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      context.read<BotBloc>().add(BotClearLogs());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('日志已清空')),
                      );
                    },
                    child: const Column(
                      children: [
                        Icon(Icons.clear_all),
                        SizedBox(height: 4),
                        Text('清空日志'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      if (context.read<BotBloc>().state is BotLoaded) {
                        final state = context.read<BotBloc>().state as BotLoaded;
                        if (state.status == BotStatus.running) {
                          context.read<BotBloc>().add(BotStop());
                          Future.delayed(const Duration(seconds: 1), () {
                            context.read<BotBloc>().add(BotStart());
                          });
                        }
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('正在重启机器人...')),
                      );
                    },
                    child: const Column(
                      children: [
                        Icon(Icons.restart_alt),
                        SizedBox(height: 4),
                        Text('重启机器人'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                    child: const Column(
                      children: [
                        Icon(Icons.settings),
                        SizedBox(height: 4),
                        Text('配置中心'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BotStatus status) {
    switch (status) {
      case BotStatus.running:
        return Colors.green;
      case BotStatus.starting:
        return Colors.yellow;
      case BotStatus.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(BotStatus status) {
    switch (status) {
      case BotStatus.running:
        return '运行中';
      case BotStatus.starting:
        return '启动中...';
      case BotStatus.stopping:
        return '停止中...';
      case BotStatus.error:
        return '连接异常';
      default:
        return '未启动';
    }
  }

  Color _getWSStatusColor(WSStatus status) {
    switch (status) {
      case WSStatus.connected:
        return Colors.green;
      case WSStatus.connecting:
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  String _getWSStatusText(WSStatus status) {
    switch (status) {
      case WSStatus.connected:
        return '已连接';
      case WSStatus.connecting:
        return '连接中...';
      default:
        return '未连接';
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}