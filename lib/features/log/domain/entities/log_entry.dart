import 'package:equatable/equatable.dart';

/// Ini model buat satu log di aplikasi.
///
/// Di sini ada info soal log, kayak waktu kejadian, level, sama pesan lognya.
class LogEntry extends Equatable {
  /// ID unik buat log ini
  final String id;

  /// Kapan log ini dibuat
  final DateTime timestamp;

  /// Level log (seberapa penting/error)
  final LogLevel level;

  /// Pesan lognya
  final String message;

  /// Tag atau kategori log (opsional)
  final String? tag;

  /// Data tambahan buat log (opsional)
  final Map<String, dynamic>? data;

  /// Stack trace kalau log error (opsional)
  final String? stackTrace;

  /// ID profil kalau log ini terkait profil tertentu (opsional)
  final String? profileId;

  /// ID peer kalau log ini terkait peer tertentu (opsional)
  final String? peerId;

  const LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.data,
    this.stackTrace,
    this.profileId,
    this.peerId,
  });

  /// Bikin salinan log, bisa ganti beberapa field
  LogEntry copyWith({
    String? id,
    DateTime? timestamp,
    LogLevel? level,
    String? message,
    String? tag,
    Map<String, dynamic>? data,
    String? stackTrace,
    String? profileId,
    String? peerId,
  }) {
    return LogEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      level: level ?? this.level,
      message: message ?? this.message,
      tag: tag ?? this.tag,
      data: data ?? this.data,
      stackTrace: stackTrace ?? this.stackTrace,
      profileId: profileId ?? this.profileId,
      peerId: peerId ?? this.peerId,
    );
  }

  /// Returns true if this log entry has a tag
  bool get hasTag => tag != null && tag!.isNotEmpty;

  /// Returns true if this log entry has additional data
  bool get hasData => data != null && data!.isNotEmpty;

  /// Returns true if this log entry has a stack trace
  bool get hasStackTrace => stackTrace != null && stackTrace!.isNotEmpty;

  /// Returns true if this log entry is related to a profile
  bool get hasProfileId => profileId != null && profileId!.isNotEmpty;

  /// Returns true if this log entry is related to a peer
  bool get hasPeerId => peerId != null && peerId!.isNotEmpty;

  /// Returns true if this log entry is an error level
  bool get isError => level == LogLevel.error;

  /// Returns true if this log entry is a warning level
  bool get isWarning => level == LogLevel.warning;

  /// Returns true if this log entry is an info level
  bool get isInfo => level == LogLevel.info;

  /// Returns true if this log entry is a debug level
  bool get isDebug => level == LogLevel.debug;

  /// Returns true if this log entry is a verbose level
  bool get isVerbose => level == LogLevel.verbose;

  /// Returns the formatted timestamp string
  String get formattedTimestamp {
    return timestamp.toIso8601String();
  }

  /// Returns the formatted timestamp for display
  String get displayTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return timestamp.toString().substring(0, 16);
    }
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        level,
        message,
        tag,
        data,
        stackTrace,
        profileId,
        peerId,
      ];
}

/// Represents the severity level of a log entry.
enum LogLevel {
  /// Verbose level - detailed information for debugging
  verbose,

  /// Debug level - debugging information
  debug,

  /// Info level - general informational messages
  info,

  /// Warning level - warning messages
  warning,

  /// Error level - error messages
  error,

  /// Fatal level - critical errors that may cause the application to crash
  fatal,
}

/// Extension on LogLevel to provide additional utility methods
extension LogLevelExtension on LogLevel {
  /// Returns the display name of the log level
  String get displayName {
    switch (this) {
      case LogLevel.verbose:
        return 'VERBOSE';
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.fatal:
        return 'FATAL';
    }
  }

  /// Returns the short name of the log level (first character)
  String get shortName {
    switch (this) {
      case LogLevel.verbose:
        return 'V';
      case LogLevel.debug:
        return 'D';
      case LogLevel.info:
        return 'I';
      case LogLevel.warning:
        return 'W';
      case LogLevel.error:
        return 'E';
      case LogLevel.fatal:
        return 'F';
    }
  }

  /// Returns the numeric value of the log level for comparison
  int get value {
    switch (this) {
      case LogLevel.verbose:
        return 0;
      case LogLevel.debug:
        return 1;
      case LogLevel.info:
        return 2;
      case LogLevel.warning:
        return 3;
      case LogLevel.error:
        return 4;
      case LogLevel.fatal:
        return 5;
    }
  }

  /// Returns true if this log level is equal to or higher than the given level
  bool isAtLeast(LogLevel other) {
    return value >= other.value;
  }

  /// Returns the color code for the log level (for terminal output)
  String get colorCode {
    switch (this) {
      case LogLevel.verbose:
        return '\x1B[90m'; // Gray
      case LogLevel.debug:
        return '\x1B[36m'; // Cyan
      case LogLevel.info:
        return '\x1B[32m'; // Green
      case LogLevel.warning:
        return '\x1B[33m'; // Yellow
      case LogLevel.error:
        return '\x1B[31m'; // Red
      case LogLevel.fatal:
        return '\x1B[35m'; // Magenta
    }
  }

  /// Returns the reset color code
  static String get resetColor => '\x1B[0m';
}
