import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../bloc/bot_bloc.dart';

enum LogLevel { all, info, error, warn, debug }

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  LogLevel _selectedLevel = LogLevel.all;
  final ScrollController _scrollController = ScrollController();

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
    final filteredLogs = _filterLogs(state.logs);

    return Column(
      children: [
        _buildFilterTabs(),
        _buildActions(context),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: filteredLogs.length,
            itemBuilder: (context, index) {
              return _buildLogItem(filteredLogs[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: LogLevel.values.map((level) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(_getLevelLabel(level)),
                selected: _selectedLevel == level,
                onSelected: (selected) {
                  setState(() {
                    _selectedLevel = level;
                  });
                },
                selectedColor: Colors.blue,
                backgroundColor: Colors.grey[100],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              context.read<BotBloc>().add(BotClearLogs());
              Fluttertoast.showToast(msg: '日志已清空');
            },
            child: const Text('清空日志'),
          ),
          TextButton(
            onPressed: () {
              _copyAllLogs(context);
            },
            child: const Text('复制全部'),
          ),
          TextButton(
            onPressed: () {
              _exportLogs(context);
            },
            child: const Text('导出日志'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(LogEntry log) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderBottom: Border(color: Colors.grey[100]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                log.timestamp,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getLevelColor(log.level),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.level.toUpperCase(),
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            log.message,
            style: TextStyle(
              color: _getLevelTextColor(log.level),
            ),
          ),
        ],
      ),
    );
  }

  List<LogEntry> _filterLogs(List<LogEntry> logs) {
    if (_selectedLevel == LogLevel.all) {
      return logs;
    }
    return logs.where((log) => log.level == _getLevelString(_selectedLevel)).toList();
  }

  String _getLevelLabel(LogLevel level) {
    switch (level) {
      case LogLevel.all:
        return '全部';
      case LogLevel.info:
        return 'Info';
      case LogLevel.error:
        return 'Error';
      case LogLevel.warn:
        return 'Warn';
      case LogLevel.debug:
        return 'Debug';
    }
  }

  String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.all:
        return '';
      case LogLevel.info:
        return 'info';
      case LogLevel.error:
        return 'error';
      case LogLevel.warn:
        return 'warn';
      case LogLevel.debug:
        return 'debug';
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'error':
        return Colors.red;
      case 'warn':
        return Colors.orange;
      case 'debug':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getLevelTextColor(String level) {
    switch (level.toLowerCase()) {
      case 'error':
        return Colors.red[800]!;
      case 'warn':
        return Colors.orange[800]!;
      case 'debug':
        return Colors.blue[800]!;
      default:
        return Colors.black87;
    }
  }

  void _copyAllLogs(BuildContext context) {
    final state = context.read<BotBloc>().state;
    if (state is BotLoaded) {
      final logsText = state.logs.map((log) {
        return '[${log.timestamp}] [${log.level}] ${log.message}';
      }).join('\n');
      Clipboard.setData(ClipboardData(text: logsText));
      Fluttertoast.showToast(msg: '日志已复制');
    }
  }

  void _exportLogs(BuildContext context) {
    Fluttertoast.showToast(msg: '日志导出功能开发中');
  }
}