import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../bloc/bot_bloc.dart';

class RulesPage extends StatefulWidget {
  const RulesPage({super.key});

  @override
  State<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> {
  List<int> _selectedRules = [];

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
    return Column(
      children: [
        if (_selectedRules.isNotEmpty)
          _buildBatchActions(context),
        Expanded(
          child: state.rules.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: state.rules.length,
                  itemBuilder: (context, index) {
                    final rule = state.rules[index];
                    return _buildRuleItem(context, rule);
                  },
                ),
        ),
        _buildAddButton(context),
      ],
    );
  }

  Widget _buildBatchActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Text('已选择 ${_selectedRules.length} 条'),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () {
              _toggleSelectedRules(context, true);
            },
            child: const Text('批量启用'),
          ),
          TextButton(
            onPressed: () {
              _toggleSelectedRules(context, false);
            },
            child: const Text('批量禁用'),
          ),
          TextButton(
            onPressed: () {
              _deleteSelectedRules(context);
            },
            child: const Text('批量删除', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedRules = [];
              });
            },
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无回复规则'),
          Text('点击下方按钮添加新规则'),
        ],
      ),
    );
  }

  Widget _buildRuleItem(BuildContext context, Rule rule) {
    final isSelected = _selectedRules.contains(rule.id);

    return ListTile(
      leading: Checkbox(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedRules.add(rule.id);
            } else {
              _selectedRules.remove(rule.id);
            }
          });
        },
      ),
      title: Text(rule.keyword),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_getMatchModeText(rule.matchMode)),
              const SizedBox(width: 8),
              Text(_getScopeText(rule.triggerScope)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            rule.replyContent.length > 50
                ? '${rule.replyContent.substring(0, 50)}...'
                : rule.replyContent,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: rule.enabled,
            onChanged: (value) {
              context.read<BotBloc>().add(BotToggleRule(ruleId: rule.id));
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditDialog(context, rule);
            },
          ),
        ],
      ),
      onTap: () {
        _showEditDialog(context, rule);
      },
      onLongPress: () {
        setState(() {
          if (_selectedRules.contains(rule.id)) {
            _selectedRules.remove(rule.id);
          } else {
            _selectedRules.add(rule.id);
          }
        });
      },
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: FloatingActionButton(
        onPressed: () {
          _showAddDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String keyword = '';
    String matchMode = 'exact';
    String scope = 'all';
    String replyContent = '';
    String replyType = 'text';
    int rateLimit = 1;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加规则'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: '触发关键词'),
                    validator: (value) => value?.isEmpty ?? true ? '请输入关键词' : null,
                    onSaved: (value) => keyword = value ?? '',
                  ),
                  DropdownButtonFormField(
                    value: matchMode,
                    items: [
                      const DropdownMenuItem(value: 'exact', child: Text('精准匹配')),
                      const DropdownMenuItem(value: 'fuzzy', child: Text('模糊匹配')),
                      const DropdownMenuItem(value: 'regex', child: Text('正则匹配')),
                    ],
                    onChanged: (value) => matchMode = value ?? 'exact',
                    decoration: const InputDecoration(labelText: '匹配模式'),
                  ),
                  DropdownButtonFormField(
                    value: scope,
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('全部')),
                      const DropdownMenuItem(value: 'all_groups', child: Text('全部群聊')),
                      const DropdownMenuItem(value: 'all_private', child: Text('全部私聊')),
                    ],
                    onChanged: (value) => scope = value ?? 'all',
                    decoration: const InputDecoration(labelText: '触发范围'),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: '回复内容'),
                    maxLines: 3,
                    validator: (value) => value?.isEmpty ?? true ? '请输入回复内容' : null,
                    onSaved: (value) => replyContent = value ?? '',
                  ),
                  DropdownButtonFormField(
                    value: replyType,
                    items: [
                      const DropdownMenuItem(value: 'text', child: Text('文本')),
                      const DropdownMenuItem(value: 'image', child: Text('图片')),
                      const DropdownMenuItem(value: 'emoji', child: Text('表情')),
                    ],
                    onChanged: (value) => replyType = value ?? 'text',
                    decoration: const InputDecoration(labelText: '回复类型'),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: '频率限制(秒)'),
                    keyboardType: TextInputType.number,
                    initialValue: '1',
                    onSaved: (value) => rateLimit = int.tryParse(value ?? '1') ?? 1,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  context.read<BotBloc>().add(BotAddRule(rule: {
                    'keyword': keyword,
                    'match_mode': matchMode,
                    'trigger_scope': scope,
                    'reply_content': replyContent,
                    'reply_type': replyType,
                    'rate_limit': rateLimit,
                    'enabled': true,
                  }));
                  Navigator.pop(context);
                  Fluttertoast.showToast(msg: '规则添加成功');
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Rule rule) {
    final formKey = GlobalKey<FormState>();
    String keyword = rule.keyword;
    String matchMode = rule.matchMode;
    String scope = rule.triggerScope;
    String replyContent = rule.replyContent;
    String replyType = rule.replyType;
    int rateLimit = rule.rateLimit;
    bool enabled = rule.enabled;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑规则'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: keyword,
                    decoration: const InputDecoration(labelText: '触发关键词'),
                    validator: (value) => value?.isEmpty ?? true ? '请输入关键词' : null,
                    onSaved: (value) => keyword = value ?? '',
                  ),
                  DropdownButtonFormField(
                    value: matchMode,
                    items: [
                      const DropdownMenuItem(value: 'exact', child: Text('精准匹配')),
                      const DropdownMenuItem(value: 'fuzzy', child: Text('模糊匹配')),
                      const DropdownMenuItem(value: 'regex', child: Text('正则匹配')),
                    ],
                    onChanged: (value) => matchMode = value ?? 'exact',
                    decoration: const InputDecoration(labelText: '匹配模式'),
                  ),
                  DropdownButtonFormField(
                    value: scope,
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('全部')),
                      const DropdownMenuItem(value: 'all_groups', child: Text('全部群聊')),
                      const DropdownMenuItem(value: 'all_private', child: Text('全部私聊')),
                    ],
                    onChanged: (value) => scope = value ?? 'all',
                    decoration: const InputDecoration(labelText: '触发范围'),
                  ),
                  TextFormField(
                    initialValue: replyContent,
                    decoration: const InputDecoration(labelText: '回复内容'),
                    maxLines: 3,
                    validator: (value) => value?.isEmpty ?? true ? '请输入回复内容' : null,
                    onSaved: (value) => replyContent = value ?? '',
                  ),
                  DropdownButtonFormField(
                    value: replyType,
                    items: [
                      const DropdownMenuItem(value: 'text', child: Text('文本')),
                      const DropdownMenuItem(value: 'image', child: Text('图片')),
                      const DropdownMenuItem(value: 'emoji', child: Text('表情')),
                    ],
                    onChanged: (value) => replyType = value ?? 'text',
                    decoration: const InputDecoration(labelText: '回复类型'),
                  ),
                  TextFormField(
                    initialValue: rateLimit.toString(),
                    decoration: const InputDecoration(labelText: '频率限制(秒)'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => rateLimit = int.tryParse(value ?? '1') ?? 1,
                  ),
                  SwitchListTile(
                    title: const Text('启用规则'),
                    value: enabled,
                    onChanged: (value) => enabled = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  context.read<BotBloc>().add(BotUpdateRule(ruleId: rule.id, rule: {
                    'keyword': keyword,
                    'match_mode': matchMode,
                    'trigger_scope': scope,
                    'reply_content': replyContent,
                    'reply_type': replyType,
                    'rate_limit': rateLimit,
                    'enabled': enabled,
                  }));
                  Navigator.pop(context);
                  Fluttertoast.showToast(msg: '规则更新成功');
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _toggleSelectedRules(BuildContext context, bool enabled) {
    for (final id in _selectedRules) {
      context.read<BotBloc>().add(BotToggleRule(ruleId: id));
    }
    setState(() {
      _selectedRules = [];
    });
    Fluttertoast.showToast(msg: '操作完成');
  }

  void _deleteSelectedRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除选中的 ${_selectedRules.length} 条规则吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                for (final id in _selectedRules) {
                  context.read<BotBloc>().add(BotDeleteRule(ruleId: id));
                }
                setState(() {
                  _selectedRules = [];
                });
                Navigator.pop(context);
                Fluttertoast.showToast(msg: '删除完成');
              },
              child: const Text('确定', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _getMatchModeText(String mode) {
    switch (mode) {
      case 'exact':
        return '精准匹配';
      case 'fuzzy':
        return '模糊匹配';
      case 'regex':
        return '正则匹配';
      default:
        return mode;
    }
  }

  String _getScopeText(String scope) {
    switch (scope) {
      case 'all':
        return '全部';
      case 'all_groups':
        return '全部群聊';
      case 'all_private':
        return '全部私聊';
      default:
        return scope;
    }
  }
}