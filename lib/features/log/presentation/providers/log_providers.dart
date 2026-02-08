import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:vpn_client_wireguard_flutter/features/log/domain/entities/log_entry.dart';

// State sederhana buat nyimpen log di memori (MVP)
class LogStateNotifier extends StateNotifier<List<LogEntry>> {
  LogStateNotifier() : super(const []);

  final Uuid _uuid = const Uuid();

  void addLog({
    required LogLevel level,
    required String message,
    String? tag,
    Map<String, dynamic>? data,
    String? profileId,
  }) {
    final entry = LogEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      data: data,
      profileId: profileId,
    );
    state = [entry, ...state];
  }

  void clearLogs() {
    state = const [];
  }
}

// Provider list log
final logListProvider =
    StateNotifierProvider<LogStateNotifier, List<LogEntry>>((ref) {
  return LogStateNotifier();
});
