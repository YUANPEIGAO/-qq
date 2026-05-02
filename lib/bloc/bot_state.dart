part of 'bot_bloc.dart';

enum BotStatus {
  initial,
  starting,
  running,
  stopping,
  stopped,
  error,
}

enum WSStatus {
  connected,
  disconnected,
  connecting,
}

class BotState extends Equatable {
  const BotState();

  @override
  List<Object?> get props => [];
}

class BotInitial extends BotState {}

class BotErrorState extends BotState {
  final String error;

  const BotErrorState({required this.error});

  @override
  List<Object?> get props => [error];
}

class BotLoaded extends BotState {
  final BotStatus status;
  final String qqId;
  final WSStatus wsStatus;
  final BotConfig config;
  final List<LogEntry> logs;
  final List<Rule> rules;
  final BotStats stats;
  final List<UpdateInfo> updates;
  final List<MemoryItem> memories;
  final String errorMessage;

  const BotLoaded({
    required this.status,
    required this.qqId,
    required this.wsStatus,
    required this.config,
    required this.logs,
    required this.rules,
    required this.stats,
    required this.updates,
    required this.memories,
    required this.errorMessage,
  });

  BotLoaded copyWith({
    BotStatus? status,
    String? qqId,
    WSStatus? wsStatus,
    BotConfig? config,
    List<LogEntry>? logs,
    List<Rule>? rules,
    BotStats? stats,
    List<UpdateInfo>? updates,
    List<MemoryItem>? memories,
    String? errorMessage,
  }) {
    return BotLoaded(
      status: status ?? this.status,
      qqId: qqId ?? this.qqId,
      wsStatus: wsStatus ?? this.wsStatus,
      config: config ?? this.config,
      logs: logs ?? this.logs,
      rules: rules ?? this.rules,
      stats: stats ?? this.stats,
      updates: updates ?? this.updates,
      memories: memories ?? this.memories,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        qqId,
        wsStatus,
        config,
        logs,
        rules,
        stats,
        updates,
        memories,
        errorMessage,
      ];
}

class BotConfig extends Equatable {
  final String wsUrl;
  final int port;
  final String accessToken;
  final String qqId;
  final bool autoReconnect;
  final int reconnectInterval;
  final int maxReconnectAttempts;
  final bool globalReplyEnabled;
  final bool privateEnabled;
  final bool groupEnabled;
  final bool autoUpdateEnabled;
  final String updateSource;
  final bool foregroundServiceEnabled;

  const BotConfig({
    required this.wsUrl,
    required this.port,
    required this.accessToken,
    required this.qqId,
    required this.autoReconnect,
    required this.reconnectInterval,
    required this.maxReconnectAttempts,
    required this.globalReplyEnabled,
    required this.privateEnabled,
    required this.groupEnabled,
    required this.autoUpdateEnabled,
    required this.updateSource,
    required this.foregroundServiceEnabled,
  });

  Map<String, dynamic> toJson() {
    return {
      'ws_url': wsUrl,
      'port': port,
      'access_token': accessToken,
      'qq_id': qqId,
      'auto_reconnect': autoReconnect,
      'reconnect_interval': reconnectInterval,
      'max_reconnect_attempts': maxReconnectAttempts,
      'global_reply_enabled': globalReplyEnabled,
      'private_enabled': privateEnabled,
      'group_enabled': groupEnabled,
      'auto_update_enabled': autoUpdateEnabled,
      'update_source': updateSource,
      'foreground_service_enabled': foregroundServiceEnabled,
    };
  }

  factory BotConfig.fromJson(Map<String, dynamic> json) {
    return BotConfig(
      wsUrl: json['ws_url'] as String,
      port: json['port'] as int,
      accessToken: json['access_token'] as String,
      qqId: json['qq_id'] as String,
      autoReconnect: json['auto_reconnect'] as bool,
      reconnectInterval: json['reconnect_interval'] as int,
      maxReconnectAttempts: json['max_reconnect_attempts'] as int,
      globalReplyEnabled: json['global_reply_enabled'] as bool,
      privateEnabled: json['private_enabled'] as bool,
      groupEnabled: json['group_enabled'] as bool,
      autoUpdateEnabled: json['auto_update_enabled'] as bool,
      updateSource: json['update_source'] as String,
      foregroundServiceEnabled: json['foreground_service_enabled'] as bool,
    );
  }

  @override
  List<Object?> get props => [
        wsUrl,
        port,
        accessToken,
        qqId,
        autoReconnect,
        reconnectInterval,
        maxReconnectAttempts,
        globalReplyEnabled,
        privateEnabled,
        groupEnabled,
        autoUpdateEnabled,
        updateSource,
        foregroundServiceEnabled,
      ];
}

class LogEntry extends Equatable {
  final String timestamp;
  final String level;
  final String message;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'level': level,
      'message': message,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: json['timestamp'] as String,
      level: json['level'] as String,
      message: json['message'] as String,
    );
  }

  @override
  List<Object?> get props => [timestamp, level, message];
}

class Rule extends Equatable {
  final int id;
  final String keyword;
  final String matchMode;
  final String triggerScope;
  final String replyContent;
  final String replyType;
  final int rateLimit;
  final bool enabled;

  const Rule({
    required this.id,
    required this.keyword,
    required this.matchMode,
    required this.triggerScope,
    required this.replyContent,
    required this.replyType,
    required this.rateLimit,
    required this.enabled,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keyword': keyword,
      'match_mode': matchMode,
      'trigger_scope': triggerScope,
      'reply_content': replyContent,
      'reply_type': replyType,
      'rate_limit': rateLimit,
      'enabled': enabled,
    };
  }

  factory Rule.fromJson(Map<String, dynamic> json) {
    return Rule(
      id: json['id'] as int,
      keyword: json['keyword'] as String,
      matchMode: json['match_mode'] as String,
      triggerScope: json['trigger_scope'] as String,
      replyContent: json['reply_content'] as String,
      replyType: json['reply_type'] as String,
      rateLimit: json['rate_limit'] as int,
      enabled: json['enabled'] as bool,
    );
  }

  Rule copyWith({
    int? id,
    String? keyword,
    String? matchMode,
    String? triggerScope,
    String? replyContent,
    String? replyType,
    int? rateLimit,
    bool? enabled,
  }) {
    return Rule(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      matchMode: matchMode ?? this.matchMode,
      triggerScope: triggerScope ?? this.triggerScope,
      replyContent: replyContent ?? this.replyContent,
      replyType: replyType ?? this.replyType,
      rateLimit: rateLimit ?? this.rateLimit,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        keyword,
        matchMode,
        triggerScope,
        replyContent,
        replyType,
        rateLimit,
        enabled,
      ];
}

class BotStats extends Equatable {
  final int receivedMessages;
  final int repliedMessages;
  final int runningTime;
  final int reconnectCount;

  const BotStats({
    this.receivedMessages = 0,
    this.repliedMessages = 0,
    this.runningTime = 0,
    this.reconnectCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'received_messages': receivedMessages,
      'replied_messages': repliedMessages,
      'running_time': runningTime,
      'reconnect_count': reconnectCount,
    };
  }

  factory BotStats.fromJson(Map<String, dynamic> json) {
    return BotStats(
      receivedMessages: json['received_messages'] as int,
      repliedMessages: json['replied_messages'] as int,
      runningTime: json['running_time'] as int,
      reconnectCount: json['reconnect_count'] as int,
    );
  }

  @override
  List<Object?> get props => [
        receivedMessages,
        repliedMessages,
        runningTime,
        reconnectCount,
      ];
}

class UpdateInfo extends Equatable {
  final String version;
  final String updateTime;
  final String changelog;
  final String downloadUrl;
  final bool isForceUpdate;

  const UpdateInfo({
    required this.version,
    required this.updateTime,
    required this.changelog,
    required this.downloadUrl,
    required this.isForceUpdate,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'update_time': updateTime,
      'changelog': changelog,
      'download_url': downloadUrl,
      'is_force_update': isForceUpdate,
    };
  }

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String,
      updateTime: json['update_time'] as String,
      changelog: json['changelog'] as String,
      downloadUrl: json['download_url'] as String,
      isForceUpdate: json['is_force_update'] as bool,
    );
  }

  @override
  List<Object?> get props => [
        version,
        updateTime,
        changelog,
        downloadUrl,
        isForceUpdate,
      ];
}

class MemoryItem extends Equatable {
  final String id;
  final String key;
  final String value;
  final String qqId;
  final String createdAt;

  const MemoryItem({
    required this.id,
    required this.key,
    required this.value,
    required this.qqId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'qq_id': qqId,
      'created_at': createdAt,
    };
  }

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['id'] as String,
      key: json['key'] as String,
      value: json['value'] as String,
      qqId: json['qq_id'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  MemoryItem copyWith({
    String? id,
    String? key,
    String? value,
    String? qqId,
    String? createdAt,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      qqId: qqId ?? this.qqId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, key, value, qqId, createdAt];
}