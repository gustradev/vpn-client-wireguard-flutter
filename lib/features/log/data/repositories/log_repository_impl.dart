import 'dart:async';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:vpn_client_wireguard_flutter/core/result.dart';
import 'package:vpn_client_wireguard_flutter/features/log/domain/entities/log_entry.dart';
import 'package:vpn_client_wireguard_flutter/features/log/domain/repositories/log_repository.dart';

/// Hive adapter for LogEntry entity.
class LogEntryAdapter extends TypeAdapter<LogEntry> {
  @override
  final int typeId = 2;

  @override
  LogEntry read(BinaryReader reader) {
    return LogEntry(
      id: reader.readString(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      level: LogLevel.values[reader.readByte()],
      message: reader.readString(),
      tag: reader.readBool() ? reader.readString() : null,
      data: reader.readBool()
          ? Map<String, dynamic>.from(jsonDecode(reader.readString()))
          : null,
      stackTrace: reader.readBool() ? reader.readString() : null,
      profileId: reader.readBool() ? reader.readString() : null,
      peerId: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, LogEntry obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeByte(obj.level.index);
    writer.writeString(obj.message);
    writer.writeBool(obj.tag != null);
    if (obj.tag != null) writer.writeString(obj.tag!);
    writer.writeBool(obj.data != null);
    if (obj.data != null) writer.writeString(jsonEncode(obj.data));
    writer.writeBool(obj.stackTrace != null);
    if (obj.stackTrace != null) writer.writeString(obj.stackTrace!);
    writer.writeBool(obj.profileId != null);
    if (obj.profileId != null) writer.writeString(obj.profileId!);
    writer.writeBool(obj.peerId != null);
    if (obj.peerId != null) writer.writeString(obj.peerId!);
  }
}

/// Implementation of LogRepository using Hive for local storage.
class LogRepositoryImpl implements LogRepository {
  static const String _boxName = 'logs';
  late Box<LogEntry> _box;
  final Uuid _uuid;
  final StreamController<LogEntry> _logController =
      StreamController.broadcast();
  Duration _maxRetention = const Duration(days: 30);
  int _maxCount = 10000;

  /// Creates a new LogRepositoryImpl instance.
  LogRepositoryImpl({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  /// Initializes the repository.
  ///
  /// Must be called before any other methods.
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> init() async {
    try {
      // Register adapter
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(LogEntryAdapter());
      }

      // Open the box
      _box = await Hive.openBox<LogEntry>(_boxName);

      // Clean up old logs on initialization
      await _cleanupOldLogs();

      return Result.success(true);
    } catch (e) {
      return Result.failure(
          'Failed to initialize log repository: ${e.toString()}');
    }
  }

  @override
  Future<Result<LogEntry>> addLog(LogEntry log) async {
    try {
      await _box.put(log.id, log);
      _logController.add(log);

      // Check if we need to clean up
      if (_box.length > _maxCount) {
        await _cleanupOldLogs();
      }

      return Result.success(log);
    } catch (e) {
      return Result.failure('Failed to add log: ${e.toString()}');
    }
  }

  @override
  Future<Result<int>> addLogs(List<LogEntry> logs) async {
    try {
      var count = 0;
      for (final log in logs) {
        final result = await addLog(log);
        if (result.isSuccess) {
          count++;
        }
      }
      return Result.success(count);
    } catch (e) {
      return Result.failure('Failed to add logs: ${e.toString()}');
    }
  }

  @override
  Future<Result<LogEntry>> getLogById(String id) async {
    try {
      final log = _box.get(id);

      if (log == null) {
        return Result.failure('Log entry not found: $id');
      }

      return Result.success(log);
    } catch (e) {
      return Result.failure('Failed to get log: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<LogEntry>>> getAllLogs() async {
    try {
      final logs = _box.values.toList();
      // Sort by timestamp descending (newest first)
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Result.success(logs);
    } catch (e) {
      return Result.failure('Failed to get all logs: ${e.toString()}');
    }
  }

  @override
  Future<Result<PaginatedLogs>> getPaginatedLogs(int page, int limit) async {
    try {
      final allLogs = _box.values.toList();
      // Sort by timestamp descending
      allLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final totalEntries = allLogs.length;
      final totalPages = (totalEntries / limit).ceil();
      final startIndex = (page - 1) * limit;
      final endIndex = (startIndex + limit).clamp(0, totalEntries);

      final entries = allLogs.sublist(startIndex, endIndex);

      return Result.success(PaginatedLogs(
        entries: entries,
        currentPage: page,
        totalPages: totalPages,
        totalEntries: totalEntries,
        pageSize: limit,
      ));
    } catch (e) {
      return Result.failure('Failed to get paginated logs: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<LogEntry>>> getLogsByLevel(LogLevel level) async {
    try {
      final logs = _box.values.where((log) => log.level == level).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Result.success(logs);
    } catch (e) {
      return Result.failure('Failed to get logs by level: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<LogEntry>>> getLogsByTag(String tag) async {
    try {
      final logs = _box.values.where((log) => log.tag == tag).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Result.success(logs);
    } catch (e) {
      return Result.failure('Failed to get logs by tag: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<LogEntry>>> getLogsByProfile(String profileId) async {
    try {
      final logs = _box.values
          .where((log) => log.profileId == profileId)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Result.success(logs);
    } catch (e) {
      return Result.failure('Failed to get logs by profile: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<LogEntry>>> getLogsByPeer(String peerId) async {
    try {
      final logs = _box.values.where((log) => log.peerId == peerId).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Result.success(logs);
    } catch (e) {
      return Result.failure('Failed to get logs by peer: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<LogEntry>>> getLogsByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final logs = _box.values
          .where((log) =>
              log.timestamp.isAfter(startDate) &&
              log.timestamp.isBefore(endDate))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Result.success(logs);
    } catch (e) {
      return Result.failure(
          'Failed to get logs by date range: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<LogEntry>>> searchLogs(
    String query, {
    bool caseSensitive = false,
  }) async {
    try {
      final searchQuery = caseSensitive ? query : query.toLowerCase();
      final logs = _box.values.where((log) {
        final message = caseSensitive ? log.message : log.message.toLowerCase();
        return message.contains(searchQuery);
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Result.success(logs);
    } catch (e) {
      return Result.failure('Failed to search logs: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<LogEntry>>> getFilteredLogs(LogFilter filter) async {
    try {
      var logs = _box.values.toList();

      // Apply filters
      if (filter.level != null) {
        logs = logs.where((log) => log.level == filter.level).toList();
      }

      if (filter.tag != null) {
        logs = logs.where((log) => log.tag == filter.tag).toList();
      }

      if (filter.profileId != null) {
        logs = logs.where((log) => log.profileId == filter.profileId).toList();
      }

      if (filter.peerId != null) {
        logs = logs.where((log) => log.peerId == filter.peerId).toList();
      }

      if (filter.startDate != null) {
        logs = logs
            .where((log) => log.timestamp.isAfter(filter.startDate!))
            .toList();
      }

      if (filter.endDate != null) {
        logs = logs
            .where((log) => log.timestamp.isBefore(filter.endDate!))
            .toList();
      }

      if (filter.searchQuery != null) {
        final searchQuery = filter.caseSensitive
            ? filter.searchQuery!
            : filter.searchQuery!.toLowerCase();
        logs = logs.where((log) {
          final message =
              filter.caseSensitive ? log.message : log.message.toLowerCase();
          return message.contains(searchQuery);
        }).toList();
      }

      // Sort by timestamp descending
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return Result.success(logs);
    } catch (e) {
      return Result.failure('Failed to get filtered logs: ${e.toString()}');
    }
  }

  @override
  Future<Result<int>> getLogCount() async {
    try {
      return Result.success(_box.length);
    } catch (e) {
      return Result.failure('Failed to get log count: ${e.toString()}');
    }
  }

  @override
  Future<Result<Map<LogLevel, int>>> getLogCountByLevel() async {
    try {
      final counts = <LogLevel, int>{};
      for (final level in LogLevel.values) {
        counts[level] = 0;
      }

      for (final log in _box.values) {
        counts[log.level] = (counts[log.level] ?? 0) + 1;
      }

      return Result.success(counts);
    } catch (e) {
      return Result.failure(
          'Failed to get log count by level: ${e.toString()}');
    }
  }

  @override
  Future<Result<bool>> deleteLog(String id) async {
    try {
      await _box.delete(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to delete log: ${e.toString()}');
    }
  }

  @override
  Future<Result<int>> deleteLogs(List<String> ids) async {
    try {
      await _box.deleteAll(ids);
      return Result.success(ids.length);
    } catch (e) {
      return Result.failure('Failed to delete logs: ${e.toString()}');
    }
  }

  @override
  Future<Result<int>> deleteLogsOlderThan(DateTime date) async {
    try {
      final keysToDelete = <String>[];
      for (final key in _box.keys) {
        final log = _box.get(key);
        if (log != null && log.timestamp.isBefore(date)) {
          keysToDelete.add(key);
        }
      }

      await _box.deleteAll(keysToDelete);
      return Result.success(keysToDelete.length);
    } catch (e) {
      return Result.failure('Failed to delete old logs: ${e.toString()}');
    }
  }

  @override
  Future<Result<int>> deleteLogsByLevel(LogLevel level) async {
    try {
      final keysToDelete = <String>[];
      for (final key in _box.keys) {
        final log = _box.get(key);
        if (log != null && log.level == level) {
          keysToDelete.add(key);
        }
      }

      await _box.deleteAll(keysToDelete);
      return Result.success(keysToDelete.length);
    } catch (e) {
      return Result.failure('Failed to delete logs by level: ${e.toString()}');
    }
  }

  @override
  Future<Result<bool>> clearAllLogs() async {
    try {
      await _box.clear();
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to clear all logs: ${e.toString()}');
    }
  }

  @override
  Future<Result<String>> exportLogs(
    LogExportFormat format, {
    LogFilter? filter,
  }) async {
    try {
      final logsResult =
          filter != null ? await getFilteredLogs(filter) : await getAllLogs();

      if (!logsResult.isSuccess) {
        return Result.failure('Failed to get logs: ${logsResult.errorOrNull}');
      }

      final logs = logsResult.valueOrThrow;

      switch (format) {
        case LogExportFormat.json:
          return Result.success(_exportToJson(logs));
        case LogExportFormat.csv:
          return Result.success(_exportToCsv(logs));
        case LogExportFormat.txt:
          return Result.success(_exportToTxt(logs));
        case LogExportFormat.logcat:
          return Result.success(_exportToLogcat(logs));
      }
    } catch (e) {
      return Result.failure('Failed to export logs: ${e.toString()}');
    }
  }

  @override
  Future<Result<int>> importLogs(String data, LogExportFormat format) async {
    try {
      List<LogEntry> logs;

      switch (format) {
        case LogExportFormat.json:
          logs = _importFromJson(data);
          break;
        case LogExportFormat.csv:
          logs = _importFromCsv(data);
          break;
        case LogExportFormat.txt:
          logs = _importFromTxt(data);
          break;
        case LogExportFormat.logcat:
          logs = _importFromLogcat(data);
          break;
      }

      var count = 0;
      for (final log in logs) {
        final result = await addLog(log);
        if (result.isSuccess) {
          count++;
        }
      }

      return Result.success(count);
    } catch (e) {
      return Result.failure('Failed to import logs: ${e.toString()}');
    }
  }

  @override
  Stream<LogEntry> watchLogs() {
    return _logController.stream;
  }

  @override
  Future<Result<LogEntry?>> getOldestLog() async {
    try {
      if (_box.isEmpty) {
        return Result.success(null);
      }

      final logs = _box.values.toList();
      logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return Result.success(logs.first);
    } catch (e) {
      return Result.failure('Failed to get oldest log: ${e.toString()}');
    }
  }

  @override
  Future<Result<LogEntry?>> getNewestLog() async {
    try {
      if (_box.isEmpty) {
        return Result.success(null);
      }

      final logs = _box.values.toList();
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Result.success(logs.first);
    } catch (e) {
      return Result.failure('Failed to get newest log: ${e.toString()}');
    }
  }

  @override
  Future<Result<LogStatistics>> getLogStatistics() async {
    try {
      final logs = _box.values.toList();

      if (logs.isEmpty) {
        return Result.success(LogStatistics(
          totalEntries: 0,
          entriesByLevel: {},
          entriesByTag: {},
          entriesByProfile: {},
          averageLogsPerDay: 0,
        ));
      }

      // Count by level
      final entriesByLevel = <LogLevel, int>{};
      for (final level in LogLevel.values) {
        entriesByLevel[level] = 0;
      }
      for (final log in logs) {
        entriesByLevel[log.level] = (entriesByLevel[log.level] ?? 0) + 1;
      }

      // Count by tag
      final entriesByTag = <String, int>{};
      for (final log in logs) {
        if (log.tag != null) {
          entriesByTag[log.tag!] = (entriesByTag[log.tag] ?? 0) + 1;
        }
      }

      // Count by profile
      final entriesByProfile = <String, int>{};
      for (final log in logs) {
        if (log.profileId != null) {
          entriesByProfile[log.profileId!] =
              (entriesByProfile[log.profileId] ?? 0) + 1;
        }
      }

      // Calculate timestamps
      logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final oldestEntry = logs.first.timestamp;
      final newestEntry = logs.last.timestamp;

      // Calculate average logs per day
      final duration = newestEntry.difference(oldestEntry);
      final days = duration.inDays.clamp(1, 365);
      final averageLogsPerDay = logs.length / days;

      return Result.success(LogStatistics(
        totalEntries: logs.length,
        entriesByLevel: entriesByLevel,
        entriesByTag: entriesByTag,
        entriesByProfile: entriesByProfile,
        oldestEntry: oldestEntry,
        newestEntry: newestEntry,
        averageLogsPerDay: averageLogsPerDay,
      ));
    } catch (e) {
      return Result.failure('Failed to get log statistics: ${e.toString()}');
    }
  }

  @override
  Future<Result<bool>> setMaxLogRetention(Duration duration) async {
    try {
      _maxRetention = duration;
      await _cleanupOldLogs();
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to set max log retention: ${e.toString()}');
    }
  }

  @override
  Future<Result<Duration>> getMaxLogRetention() async {
    return Result.success(_maxRetention);
  }

  @override
  Future<Result<bool>> setMaxLogCount(int count) async {
    try {
      _maxCount = count;
      await _cleanupOldLogs();
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to set max log count: ${e.toString()}');
    }
  }

  @override
  Future<Result<int>> getMaxLogCount() async {
    return Result.success(_maxCount);
  }

  /// Cleans up old logs based on retention settings.
  Future<void> _cleanupOldLogs() async {
    try {
      final cutoffDate = DateTime.now().subtract(_maxRetention);
      final keysToDelete = <String>[];

      // Delete logs older than retention period
      for (final key in _box.keys) {
        final log = _box.get(key);
        if (log != null && log.timestamp.isBefore(cutoffDate)) {
          keysToDelete.add(key);
        }
      }

      if (keysToDelete.isNotEmpty) {
        await _box.deleteAll(keysToDelete);
      }

      // If still over max count, delete oldest
      if (_box.length > _maxCount) {
        final logs = _box.values.toList();
        logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final excessCount = _box.length - _maxCount;
        final keysToDelete2 =
            logs.take(excessCount).map((log) => log.id).toList();
        await _box.deleteAll(keysToDelete2);
      }
    } catch (e) {
      // Silently fail cleanup to avoid disrupting normal operations
    }
  }

  /// Exports logs to JSON format.
  String _exportToJson(List<LogEntry> logs) {
    final json = logs
        .map((log) => {
              'id': log.id,
              'timestamp': log.timestamp.toIso8601String(),
              'level': log.level.name,
              'message': log.message,
              'tag': log.tag,
              'data': log.data,
              'stackTrace': log.stackTrace,
              'profileId': log.profileId,
              'peerId': log.peerId,
            })
        .toList();
    return jsonEncode(json);
  }

  /// Exports logs to CSV format.
  String _exportToCsv(List<LogEntry> logs) {
    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Level,Message,Tag,ProfileId,PeerId');

    for (final log in logs) {
      final timestamp = log.timestamp.toIso8601String();
      final level = log.level.name;
      final message = log.message.replaceAll(',', '\\,');
      final tag = log.tag ?? '';
      final profileId = log.profileId ?? '';
      final peerId = log.peerId ?? '';

      buffer.writeln('$timestamp,$level,$message,$tag,$profileId,$peerId');
    }

    return buffer.toString();
  }

  /// Exports logs to plain text format.
  String _exportToTxt(List<LogEntry> logs) {
    final buffer = StringBuffer();

    for (final log in logs) {
      buffer.writeln(
          '[${log.timestamp.toIso8601String()}] ${log.level.displayName}: ${log.message}');
      if (log.tag != null) {
        buffer.writeln('  Tag: ${log.tag}');
      }
      if (log.stackTrace != null) {
        buffer.writeln('  Stack Trace:');
        for (final line in log.stackTrace!.split('\n')) {
          buffer.writeln('    $line');
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Exports logs to logcat format.
  String _exportToLogcat(List<LogEntry> logs) {
    final buffer = StringBuffer();

    for (final log in logs) {
      final timestamp = log.timestamp.millisecondsSinceEpoch;
      final level = log.level.shortName;
      final tag = log.tag ?? 'VPN';
      final message = log.message;

      buffer.writeln('$timestamp $level/$tag: $message');
    }

    return buffer.toString();
  }

  /// Imports logs from JSON format.
  List<LogEntry> _importFromJson(String data) {
    try {
      final json = jsonDecode(data) as List;
      return json.map((item) {
        final map = item as Map<String, dynamic>;
        return LogEntry(
          id: map['id'] as String? ?? _uuid.v4(),
          timestamp: DateTime.parse(map['timestamp'] as String),
          level: LogLevel.values.firstWhere(
            (e) => e.name == map['level'],
            orElse: () => LogLevel.info,
          ),
          message: map['message'] as String,
          tag: map['tag'] as String?,
          data: map['data'] as Map<String, dynamic>?,
          stackTrace: map['stackTrace'] as String?,
          profileId: map['profileId'] as String?,
          peerId: map['peerId'] as String?,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Imports logs from CSV format.
  List<LogEntry> _importFromCsv(String data) {
    try {
      final lines = data.split('\n');
      final logs = <LogEntry>[];

      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(',');
        if (parts.length < 3) continue;

        logs.add(LogEntry(
          id: _uuid.v4(),
          timestamp: DateTime.parse(parts[0]),
          level: LogLevel.values.firstWhere(
            (e) => e.name == parts[1],
            orElse: () => LogLevel.info,
          ),
          message: parts[2].replaceAll('\\,', ','),
          tag: parts.length > 3 ? parts[3] : null,
          profileId: parts.length > 4 ? parts[4] : null,
          peerId: parts.length > 5 ? parts[5] : null,
        ));
      }

      return logs;
    } catch (e) {
      return [];
    }
  }

  /// Imports logs from plain text format.
  List<LogEntry> _importFromTxt(String data) {
    try {
      final lines = data.split('\n');
      final logs = <LogEntry>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        // Parse format: [timestamp] LEVEL: message
        final match = RegExp(r'\[([^\]]+)\]\s+(\w+):\s+(.+)').firstMatch(line);
        if (match != null) {
          logs.add(LogEntry(
            id: _uuid.v4(),
            timestamp: DateTime.parse(match.group(1)!),
            level: LogLevel.values.firstWhere(
              (e) => e.name == match.group(2),
              orElse: () => LogLevel.info,
            ),
            message: match.group(3)!,
          ));
        }
      }

      return logs;
    } catch (e) {
      return [];
    }
  }

  /// Imports logs from logcat format.
  List<LogEntry> _importFromLogcat(String data) {
    try {
      final lines = data.split('\n');
      final logs = <LogEntry>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        // Parse format: timestamp LEVEL/tag: message
        final match = RegExp(r'(\d+)\s+(\w+)/(\w+):\s+(.+)').firstMatch(line);
        if (match != null) {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(
            int.parse(match.group(1)!),
          );
          final level = LogLevel.values.firstWhere(
            (e) => e.shortName == match.group(2),
            orElse: () => LogLevel.info,
          );

          logs.add(LogEntry(
            id: _uuid.v4(),
            timestamp: timestamp,
            level: level,
            message: match.group(4)!,
            tag: match.group(3),
          ));
        }
      }

      return logs;
    } catch (e) {
      return [];
    }
  }

  /// Disposes the repository and cleans up resources.
  void dispose() {
    _logController.close();
  }
}
