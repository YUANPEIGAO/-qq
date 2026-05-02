part of 'bot_bloc.dart';

abstract class BotEvent extends Equatable {
  const BotEvent();

  @override
  List<Object?> get props => [];
}

class BotInitialize extends BotEvent {}

class BotStart extends BotEvent {}

class BotStop extends BotEvent {}

class BotLogReceived extends BotEvent {
  final LogEntry log;

  const BotLogReceived({required this.log});

  @override
  List<Object?> get props => [log];
}

class BotStatsReceived extends BotEvent {
  final BotStats stats;

  const BotStatsReceived({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class BotError extends BotEvent {
  final String error;

  const BotError({required this.error});

  @override
  List<Object?> get props => [error];
}

class BotAddRule extends BotEvent {
  final Map<String, dynamic> rule;

  const BotAddRule({required this.rule});

  @override
  List<Object?> get props => [rule];
}

class BotUpdateRule extends BotEvent {
  final int ruleId;
  final Map<String, dynamic> rule;

  const BotUpdateRule({required this.ruleId, required this.rule});

  @override
  List<Object?> get props => [ruleId, rule];
}

class BotDeleteRule extends BotEvent {
  final int ruleId;

  const BotDeleteRule({required this.ruleId});

  @override
  List<Object?> get props => [ruleId];
}

class BotToggleRule extends BotEvent {
  final int ruleId;

  const BotToggleRule({required this.ruleId});

  @override
  List<Object?> get props => [ruleId];
}

class BotImportRules extends BotEvent {
  final List<dynamic> rules;

  const BotImportRules({required this.rules});

  @override
  List<Object?> get props => [rules];
}

class BotExportRules extends BotEvent {
  final String path;

  const BotExportRules({required this.path});

  @override
  List<Object?> get props => [path];
}

class BotUpdateConfig extends BotEvent {
  final BotConfig config;

  const BotUpdateConfig({required this.config});

  @override
  List<Object?> get props => [config];
}

class BotClearLogs extends BotEvent {}

class BotCheckUpdate extends BotEvent {
  final bool isManual;

  const BotCheckUpdate({this.isManual = false});

  @override
  List<Object?> get props => [isManual];
}

class BotAddMemory extends BotEvent {
  final Map<String, dynamic> memory;

  const BotAddMemory({required this.memory});

  @override
  List<Object?> get props => [memory];
}

class BotUpdateMemory extends BotEvent {
  final String memoryId;
  final Map<String, dynamic> memory;

  const BotUpdateMemory({required this.memoryId, required this.memory});

  @override
  List<Object?> get props => [memoryId, memory];
}

class BotDeleteMemory extends BotEvent {
  final String memoryId;

  const BotDeleteMemory({required this.memoryId});

  @override
  List<Object?> get props => [memoryId];
}

class BotClearMemories extends BotEvent {}

class BotLoadMemories extends BotEvent {
  final String? qqId;

  const BotLoadMemories({this.qqId});

  @override
  List<Object?> get props => [qqId];
}