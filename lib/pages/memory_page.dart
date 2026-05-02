import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../bloc/bot_bloc.dart';

class MemoryPage extends StatefulWidget {
  const MemoryPage({super.key});

  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  List<String> _selectedMemories = [];
  String? _filterQqId;

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
    final filteredMemories = _filterQqId != null && _filterQqId!.isNotEmpty
        ? state.memories.where((m) => m.qqId == _filterQqId).toList()
        : state.memories;

    return Column(
      children: [
        if (_selectedMemories.isNotEmpty)
          _buildBatchActions(context),
        _buildSearchBar(state),
        Expanded(
          child: filteredMemories.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: filteredMemories.length,
                  itemBuilder: (context, index) {
                    final memory = filteredMemories[index];
                    return _buildMemoryItem(context, memory);
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
          Text('已选择 ${_selectedMemories.length} 条'),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedMemories = [];
              });
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _deleteSelectedMemories(context);
            },
            child: const Text('批量删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BotLoaded state) {
    final qqIds = state.memories
        .map((m) => m.qqId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜索关键词...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _filterQqId = value.isEmpty ? null : value;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            hint: const Text('筛选QQ'),
            value: _filterQqId,
            items: [
              const DropdownMenuItem(value: null, child: Text('全部')),
              ...qqIds.map((id) => DropdownMenuItem(
                    value: id,
                    child: Text(id),
                  )),
            ],
            onChanged: (value) {
              setState(() {
                _filterQqId = value;
              });
            },
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
          Icon(Icons.storage, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无记忆数据'),
          Text('点击下方按钮添加新记忆'),
        ],
      ),
    );
  }

  Widget _buildMemoryItem(BuildContext context, MemoryItem memory) {
    final isSelected = _selectedMemories.contains(memory.id);

    return ListTile(
      leading: Checkbox(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedMemories.add(memory.id);
            } else {
              _selectedMemories.remove(memory.id);
            }
          });
        },
      ),
      title: Text(memory.key),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(memory.value.length > 50
              ? '${memory.value.substring(0, 50)}...'
              : memory.value),
          const SizedBox(height: 4),
          Row(
            children: [
              if (memory.qqId.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('QQ: ${memory.qqId}'),
                ),
              const SizedBox(width: 8),
              Text(
                _formatDate(memory.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditDialog(context, memory);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _deleteMemory(context, memory.id);
            },
          ),
        ],
      ),
      onLongPress: () {
        setState(() {
          if (_selectedMemories.contains(memory.id)) {
            _selectedMemories.remove(memory.id);
          } else {
            _selectedMemories.add(memory.id);
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
    String key = '';
    String value = '';
    String qqId = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加记忆'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: '关键词'),
                    validator: (value) => value?.isEmpty ?? true ? '请输入关键词' : null,
                    onSaved: (value) => key = value ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: '值'),
                    maxLines: 3,
                    validator: (value) => value?.isEmpty ?? true ? '请输入值' : null,
                    onSaved: (value) => value = value ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: '关联QQ号（可选）'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => qqId = value ?? '',
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
                  context.read<BotBloc>().add(BotAddMemory(memory: {
                    'key': key,
                    'value': value,
                    'qq_id': qqId,
                  }));
                  Navigator.pop(context);
                  Fluttertoast.showToast(msg: '记忆添加成功');
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, MemoryItem memory) {
    final formKey = GlobalKey<FormState>();
    String key = memory.key;
    String value = memory.value;
    String qqId = memory.qqId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑记忆'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: key,
                    decoration: const InputDecoration(labelText: '关键词'),
                    validator: (value) => value?.isEmpty ?? true ? '请输入关键词' : null,
                    onSaved: (value) => key = value ?? '',
                  ),
                  TextFormField(
                    initialValue: value,
                    decoration: const InputDecoration(labelText: '值'),
                    maxLines: 3,
                    validator: (value) => value?.isEmpty ?? true ? '请输入值' : null,
                    onSaved: (value) => value = value ?? '',
                  ),
                  TextFormField(
                    initialValue: qqId,
                    decoration: const InputDecoration(labelText: '关联QQ号（可选）'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => qqId = value ?? '',
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
                  context.read<BotBloc>().add(BotUpdateMemory(
                    memoryId: memory.id,
                    memory: {
                      'key': key,
                      'value': value,
                      'qq_id': qqId,
                    },
                  ));
                  Navigator.pop(context);
                  Fluttertoast.showToast(msg: '记忆更新成功');
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _deleteMemory(BuildContext context, String memoryId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这条记忆吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                context.read<BotBloc>().add(BotDeleteMemory(memoryId: memoryId));
                Navigator.pop(context);
                Fluttertoast.showToast(msg: '删除成功');
              },
              child: const Text('确定', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteSelectedMemories(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除选中的 ${_selectedMemories.length} 条记忆吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                for (final id in _selectedMemories) {
                  context.read<BotBloc>().add(BotDeleteMemory(memoryId: id));
                }
                setState(() {
                  _selectedMemories = [];
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateString;
    }
  }
}