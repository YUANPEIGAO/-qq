import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'bot_state.dart';
part 'bot_event.dart';

class BotBloc extends Bloc<BotEvent, BotState> {
  final SharedPreferences prefs;
  final MethodChannel _channel = const MethodChannel('com.example.qq_chat_bot/bot');
  Timer? _statsTimer;
  Timer? _logTimer;

  BotBloc(this.prefs) : super(BotInitial()) {
    on<BotInitialize>(_onInitialize);
    on<BotStart>(_onStart);
    on<BotStop>(_onStop);
    on<BotLogReceived>(_onLogReceived);
    on<BotStatsReceived>(_onStatsReceived);
    on<BotError>(_onError);
    on<BotAddRule>(_onAddRule);
    on<BotUpdateRule>(_onUpdateRule);
    on<BotDeleteRule>(_onDeleteRule);
    on<BotToggleRule>(_onToggleRule);
    on<BotImportRules>(_onImportRules);
    on<BotExportRules>(_onExportRules);
    on<BotUpdateConfig>(_onUpdateConfig);
    on<BotClearLogs>(_onClearLogs);
    on<BotCheckUpdate>(_onCheckUpdate);
    on<BotAddMemory>(_onAddMemory);
    on<BotUpdateMemory>(_onUpdateMemory);
    on<BotDeleteMemory>(_onDeleteMemory);
    on<BotClearMemories>(_onClearMemories);
    on<BotLoadMemories>(_onLoadMemories);
  }

  Future<void> _onInitialize(BotInitialize event, Emitter<BotState> emit) async {
    try {
      final config = _loadConfig();
      final logs = await _loadLogs();
      final rules = await _loadRules();
      final updates = await _loadUpdates();
      final memories = await _loadMemories();

      emit(BotLoaded(
        status: BotStatus.stopped,
        qqId: '',
        wsStatus: WSStatus.disconnected,
        config: config,
        logs: logs,
        rules: rules,
        stats: const BotStats(),
        updates: updates,
        memories: memories,
        errorMessage: '',
      ));

      _startLogPolling();
    } catch (e) {
      emit(BotErrorState(error: e.toString()));
    }
  }

  Future<void> _onStart(BotStart event, Emitter<BotState> emit) async {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    try {
      emit(currentState.copyWith(status: BotStatus.starting));

      await _channel.invokeMethod('startForegroundService');
      await _channel.invokeMethod('acquireWakeLock');

      final config = currentState.config;
      final pythonConfig = jsonEncode({
        'ws_url': config.wsUrl,
        'access_token': config.accessToken,
      });

      await _channel.invokeMethod('initBot', {'config': pythonConfig});
      await _channel.invokeMethod('startBot');

      emit(currentState.copyWith(
        status: BotStatus.running,
        wsStatus: WSStatus.connected,
        qqId: config.qqId,
      ));

      _startStatsPolling();
    } catch (e) {
      emit(currentState.copyWith(
        status: BotStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onStop(BotStop event, Emitter<BotState> emit) async {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    try {
      emit(currentState.copyWith(status: BotStatus.stopping));

      await _channel.invokeMethod('stopBot');
      await _channel.invokeMethod('stopForegroundService');
      await _channel.invokeMethod('releaseWakeLock');

      _stopStatsPolling();

      emit(currentState.copyWith(
        status: BotStatus.stopped,
        wsStatus: WSStatus.disconnected,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        status: BotStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onLogReceived(BotLogReceived event, Emitter<BotState> emit) {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    final newLogs = List<LogEntry>.from(currentState.logs)
      ..insert(0, event.log);

    if (newLogs.length > 1000) {
      newLogs.removeRange(1000, newLogs.length);
    }

    emit(currentState.copyWith(logs: newLogs));
    _saveLogs(newLogs);
  }

  void _onStatsReceived(BotStatsReceived event, Emitter<BotState> emit) {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    emit(currentState.copyWith(stats: event.stats));
  }

  void _onError(BotError event, Emitter<BotState> emit) {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    emit(currentState.copyWith(
      status: BotStatus.error,
      errorMessage: event.error,
    ));
  }

  Future<void> _onAddRule(BotAddRule event, Emitter<BotState> emit) async {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    try {
      await _channel.invokeMethod('addRule', {'rule': jsonEncode(event.rule)});
      final rules = await _getRules();
      emit(currentState.copyWith(rules: rules));
    } catch (e) {
      emit(currentState.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateRule(BotUpdateRule event, Emitter<BotState> emit) async {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    try {
      await _channel.invokeMethod('updateRule', {
        'ruleId': event.ruleId,
        'rule': jsonEncode(event.rule),
      });
      final rules = await _getRules();
      emit(currentState.copyWith(rules: rules));
    } catch (e) {
      emit(currentState.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteRule(BotDeleteRule event, Emitter<BotState> emit) async {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    try {
      await _channel.invokeMethod('removeRule', {'ruleId': event.ruleId});
      final rules = await _getRules();
      emit(currentState.copyWith(rules: rules));
    } catch (e) {
      emit(currentState.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onToggleRule(BotToggleRule event, Emitter<BotState> emit) async {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    try {
      await _channel.invokeMethod('toggleRule', {'ruleId': event.ruleId});
      final rules = await _getRules();
      emit(currentState.copyWith(rules: rules));
    } catch (e) {
      emit(currentState.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onImportRules(BotImportRules event, Emitter<BotState> emit) async {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    try {
      await _channel.invokeMethod('importRules', {'rules': jsonEncode(event.rules)});
      final rules = await _getRules();
      emit(currentState.copyWith(rules: rules));
    } catch (e) {
      emit(currentState.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onExportRules(BotExportRules event, Emitter<BotState> emit) async {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    try {
      final result = await _channel.invokeMethod('exportRules');
      final rules = jsonDecode(result as String) as List<dynamic>;
      final file = File('${event.path}/rules.json');
      await file.writeAsString(jsonEncode(rules, indent: const ['', '  ']));
    } catch (e) {
      emit(currentState.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateConfig(BotUpdateConfig event, Emitter<BotState> emit) async {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    _saveConfig(event.config);
    emit(currentState.copyWith(config: event.config));
  }

  void _onClearLogs(BotClearLogs event, Emitter<BotState> emit) {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    emit(currentState.copyWith(logs: []));
    _saveLogs([]);
  }

  Future<void> _onCheckUpdate(BotCheckUpdate event, Emitter<BotState> emit) async {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    try {
      final result = await _channel.invokeMethod('checkUpdate');
      final updateInfo = UpdateInfo.fromJson(jsonDecode(result as String));
      final updates = List<UpdateInfo>.from(currentState.updates)
        ..insert(0, updateInfo);
      emit(currentState.copyWith(updates: updates));
    } catch (e) {
      emit(currentState.copyWith(errorMessage: e.toString()));
    }
  }

  BotConfig _loadConfig() {
    return BotConfig(
      wsUrl: prefs.getString('ws_url') ?? 'ws://localhost:8080',
      port: prefs.getInt('port') ?? 8080,
      accessToken: prefs.getString('access_token') ?? '',
      qqId: prefs.getString('qq_id') ?? '',
      autoReconnect: prefs.getBool('auto_reconnect') ?? true,
      reconnectInterval: prefs.getInt('reconnect_interval') ?? 5,
      maxReconnectAttempts: prefs.getInt('max_reconnect_attempts') ?? 10,
      globalReplyEnabled: prefs.getBool('global_reply_enabled') ?? true,
      privateEnabled: prefs.getBool('private_enabled') ?? true,
      groupEnabled: prefs.getBool('group_enabled') ?? true,
      autoUpdateEnabled: prefs.getBool('auto_update_enabled') ?? true,
      updateSource: prefs.getString('update_source') ?? 'https://github.com',
      foregroundServiceEnabled: prefs.getBool('foreground_service_enabled') ?? false,
    );
  }

  void _saveConfig(BotConfig config) {
    prefs.setString('ws_url', config.wsUrl);
    prefs.setInt('port', config.port);
    prefs.setString('access_token', config.accessToken);
    prefs.setString('qq_id', config.qqId);
    prefs.setBool('auto_reconnect', config.autoReconnect);
    prefs.setInt('reconnect_interval', config.reconnectInterval);
    prefs.setInt('max_reconnect_attempts', config.maxReconnectAttempts);
    prefs.setBool('global_reply_enabled', config.globalReplyEnabled);
    prefs.setBool('private_enabled', config.privateEnabled);
    prefs.setBool('group_enabled', config.groupEnabled);
    prefs.setBool('auto_update_enabled', config.autoUpdateEnabled);
    prefs.setString('update_source', config.updateSource);
    prefs.setBool('foreground_service_enabled', config.foregroundServiceEnabled);
  }

  Future<List<LogEntry>> _loadLogs() async {
    final logsJson = prefs.getString('logs');
    if (logsJson != null) {
      final logs = jsonDecode(logsJson) as List<dynamic>;
      return logs.map((e) => LogEntry.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  void _saveLogs(List<LogEntry> logs) {
    prefs.setString('logs', jsonEncode(logs));
  }

  Future<List<Rule>> _loadRules() async {
    try {
      final result = await _channel.invokeMethod('getRules');
      final rules = jsonDecode(result as String) as List<dynamic>;
      return rules.map((e) => Rule.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Rule>> _getRules() async {
    try {
      final result = await _channel.invokeMethod('getRules');
      final rules = jsonDecode(result as String) as List<dynamic>;
      return rules.map((e) => Rule.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<UpdateInfo>> _loadUpdates() async {
    final updatesJson = prefs.getString('updates');
    if (updatesJson != null) {
      final updates = jsonDecode(updatesJson) as List<dynamic>;
      return updates.map((e) => UpdateInfo.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  void _startStatsPolling() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final result = await _channel.invokeMethod('getStats');
        final stats = BotStats.fromJson(jsonDecode(result as String));
        add(BotStatsReceived(stats: stats));
      } catch (e) {
        // ignore
      }
    });
  }

  void _stopStatsPolling() {
    _statsTimer?.cancel();
  }

  void _startLogPolling() {
    _logTimer?.cancel();
    _logTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final result = await _channel.invokeMethod('getLogs');
        final logs = jsonDecode(result as String) as List<dynamic>;
        for (final log in logs) {
          add(BotLogReceived(log: LogEntry.fromJson(log as Map<String, dynamic>)));
        }
      } catch (e) {
        // ignore
      }
    });
  }

  Future<void> _onAddMemory(BotAddMemory event, Emitter<BotState> emit) async {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    final newMemory = MemoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      key: event.memory['key'] as String,
      value: event.memory['value'] as String,
      qqId: event.memory['qq_id'] as String? ?? '',
      createdAt: DateTime.now().toIso8601String(),
    );

    final newMemories = List<MemoryItem>.from(currentState.memories)
      ..insert(0, newMemory);

    emit(currentState.copyWith(memories: newMemories));
    _saveMemories(newMemories);
  }

  Future<void> _onUpdateMemory(BotUpdateMemory event, Emitter<BotState> emit) async {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    final newMemories = currentState.memories.map((memory) {
      if (memory.id == event.memoryId) {
        return memory.copyWith(
          key: event.memory['key'] as String? ?? memory.key,
          value: event.memory['value'] as String? ?? memory.value,
          qqId: event.memory['qq_id'] as String? ?? memory.qqId,
        );
      }
      return memory;
    }).toList();

    emit(currentState.copyWith(memories: newMemories));
    _saveMemories(newMemories);
  }

  Future<void> _onDeleteMemory(BotDeleteMemory event, Emitter<BotState> emit) async {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    final newMemories = currentState.memories
        .where((memory) => memory.id != event.memoryId)
        .toList();

    emit(currentState.copyWith(memories: newMemories));
    _saveMemories(newMemories);
  }

  Future<void> _onClearMemories(BotClearMemories event, Emitter<BotState> emit) async {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    emit(currentState.copyWith(memories: []));
    _saveMemories([]);
  }

  Future<void> _onLoadMemories(BotLoadMemories event, Emitter<BotState> emit) async {
    if (state is! BotLoaded) return;
    final currentState = state as BotLoaded;

    final memories = await _loadMemories();
    
    if (event.qqId != null && event.qqId!.isNotEmpty) {
      final filteredMemories = memories
          .where((memory) => memory.qqId == event.qqId)
          .toList();
      emit(currentState.copyWith(memories: filteredMemories));
    } else {
      emit(currentState.copyWith(memories: memories));
    }
  }

  Future<List<MemoryItem>> _loadMemories() async {
    final memoriesJson = prefs.getString('memories');
    if (memoriesJson != null) {
      final memories = jsonDecode(memoriesJson) as List<dynamic>;
      return memories.map((e) => MemoryItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return _getDefaultMemories();
  }

  void _saveMemories(List<MemoryItem> memories) {
    prefs.setString('memories', jsonEncode(memories));
  }

  List<MemoryItem> _getDefaultMemories() {
    return [
      MemoryItem(
        id: '1',
        key: 'api_url',
        value: 'http://localhost:8080',
        qqId: '',
        createdAt: DateTime.now().toIso8601String(),
      ),
      MemoryItem(
        id: '2',
        key: 'api_token',
        value: '',
        qqId: '',
        createdAt: DateTime.now().toIso8601String(),
      ),
      MemoryItem(
        id: '3',
        key: 'default_qq',
        value: '',
        qqId: '',
        createdAt: DateTime.now().toIso8601String(),
      ),
    ];
  }

  @override
  Future<void> close() {
    _statsTimer?.cancel();
    _logTimer?.cancel();
    return super.close();
  }
}