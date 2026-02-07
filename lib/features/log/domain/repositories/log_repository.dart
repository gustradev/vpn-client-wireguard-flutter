import 'package:vpn_client_wireguard_flutter/core/result.dart';
import 'package:vpn_client_wireguard_flutter/features/log/domain/entities/log_entry.dart';

/// Interface repository buat ngatur log aplikasi.
///
/// Di sini kontrak buat operasi log: bikin, ambil, filter, sama export log.
abstract class LogRepository {
  /// Tambah log baru.
  ///
  /// Kalau sukses, return [Result] berisi [LogEntry] yang baru.
  /// Kalau gagal, return error.
  Future<Result<LogEntry>> addLog(LogEntry log);

  /// Tambah banyak log sekaligus.
  ///
  /// Kalau sukses, return jumlah log yang ditambah.
  /// Kalau gagal, return error.
  Future<Result<int>> addLogs(List<LogEntry> logs);

  /// Ambil log berdasarkan ID.
  ///
  /// Kalau sukses, return [LogEntry].
  /// Kalau gagal, return error.
  Future<Result<LogEntry>> getLogById(String id);

  /// Ambil semua log.
  ///
  /// Return list [LogEntry].
  Future<Result<List<LogEntry>>> getAllLogs();

  /// Ambil log dengan pagination.
  ///
  /// [page] - Nomor halaman (mulai dari 1)
  /// [limit] - Jumlah log per halaman
  ///
  /// Return [PaginatedLogs].
  Future<Result<PaginatedLogs>> getPaginatedLogs(int page, int limit);

  /// Ambil log yang levelnya tertentu.
  ///
  /// Return list [LogEntry] yang cocok.
  Future<Result<List<LogEntry>>> getLogsByLevel(LogLevel level);

  /// Ambil log berdasarkan tag.
  ///
  /// Return list [LogEntry] yang cocok.
  Future<Result<List<LogEntry>>> getLogsByTag(String tag);

  /// Ambil log buat profil tertentu.
  ///
  /// Return list [LogEntry] yang cocok.
  Future<Result<List<LogEntry>>> getLogsByProfile(String profileId);

  /// Ambil log buat peer tertentu.
  ///
  /// Return list [LogEntry] yang cocok.
  Future<Result<List<LogEntry>>> getLogsByPeer(String peerId);

  /// Ambil log dalam rentang tanggal.
  ///
  /// [startDate] - Mulai tanggal (termasuk)
  /// [endDate] - Akhir tanggal (termasuk)
  ///
  /// Return list [LogEntry] yang cocok.
  Future<Result<List<LogEntry>>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Cari log berdasarkan isi pesan.
  ///
  /// [query] - Kata kunci pencarian
  /// [caseSensitive] - Pencarian sensitif huruf besar/kecil atau nggak
  ///
  /// Return list [LogEntry] yang cocok.
  Future<Result<List<LogEntry>>> searchLogs(
    String query, {
    bool caseSensitive = false,
  });

  /// Gets log entries with advanced filtering.
  ///
  /// Returns a [Result] containing a list of matching [LogEntry] objects.
  Future<Result<List<LogEntry>>> getFilteredLogs(LogFilter filter);

  /// Gets the count of log entries.
  ///
  /// Returns a [Result] containing the total number of log entries.
  Future<Result<int>> getLogCount();

  /// Gets the count of log entries by level.
  ///
  /// Returns a [Result] containing a map of log levels to their counts.
  Future<Result<Map<LogLevel, int>>> getLogCountByLevel();

  /// Deletes a log entry by its ID.
  ///
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> deleteLog(String id);

  /// Deletes multiple log entries by their IDs.
  ///
  /// Returns a [Result] containing the number of entries deleted on success,
  /// or an error message on failure.
  Future<Result<int>> deleteLogs(List<String> ids);

  /// Deletes log entries older than the specified date.
  ///
  /// Returns a [Result] containing the number of entries deleted on success,
  /// or an error message on failure.
  Future<Result<int>> deleteLogsOlderThan(DateTime date);

  /// Deletes log entries by level.
  ///
  /// Returns a [Result] containing the number of entries deleted on success,
  /// or an error message on failure.
  Future<Result<int>> deleteLogsByLevel(LogLevel level);

  /// Clears all log entries.
  ///
  /// This is a destructive operation and cannot be undone.
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> clearAllLogs();

  /// Exports log entries to a file.
  ///
  /// [format] - The export format (JSON, CSV, TXT)
  /// [filter] - Optional filter to apply before exporting
  ///
  /// Returns a [Result] containing the exported data string on success,
  /// or an error message on failure.
  Future<Result<String>> exportLogs(
    LogExportFormat format, {
    LogFilter? filter,
  });

  /// Imports log entries from a file.
  ///
  /// [data] - The log data to import
  /// [format] - The format of the imported data
  ///
  /// Returns a [Result] containing the number of entries imported on success,
  /// or an error message on failure.
  Future<Result<int>> importLogs(String data, LogExportFormat format);

  /// Subscribes to new log entries.
  ///
  /// Returns a [Stream] that emits new [LogEntry] objects as they are added.
  Stream<LogEntry> watchLogs();

  /// Gets the oldest log entry.
  ///
  /// Returns a [Result] containing the oldest [LogEntry],
  /// or null if no logs exist.
  Future<Result<LogEntry?>> getOldestLog();

  /// Gets the newest log entry.
  ///
  /// Returns a [Result] containing the newest [LogEntry],
  /// or null if no logs exist.
  Future<Result<LogEntry?>> getNewestLog();

  /// Gets log statistics.
  ///
  /// Returns a [Result] containing [LogStatistics] on success.
  Future<Result<LogStatistics>> getLogStatistics();

  /// Sets the maximum log retention period.
  ///
  /// Logs older than this period will be automatically deleted.
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> setMaxLogRetention(Duration duration);

  /// Gets the current maximum log retention period.
  ///
  /// Returns a [Result] containing the retention duration.
  Future<Result<Duration>> getMaxLogRetention();

  /// Sets the maximum number of log entries to keep.
  ///
  /// When this limit is exceeded, the oldest entries will be deleted.
  /// Returns a [Result] containing true on success,
  /// or an error message on failure.
  Future<Result<bool>> setMaxLogCount(int count);

  /// Gets the current maximum log count.
  ///
  /// Returns a [Result] containing the maximum log count.
  Future<Result<int>> getMaxLogCount();
}

/// Represents paginated log results.
class PaginatedLogs {
  /// The log entries for the current page
  final List<LogEntry> entries;

  /// The current page number (1-indexed)
  final int currentPage;

  /// The total number of pages
  final int totalPages;

  /// The total number of log entries
  final int totalEntries;

  /// The number of entries per page
  final int pageSize;

  const PaginatedLogs({
    required this.entries,
    required this.currentPage,
    required this.totalPages,
    required this.totalEntries,
    required this.pageSize,
  });

  /// Returns true if there is a next page
  bool get hasNextPage => currentPage < totalPages;

  /// Returns true if there is a previous page
  bool get hasPreviousPage => currentPage > 1;

  /// Returns true if this is the first page
  bool get isFirstPage => currentPage == 1;

  /// Returns true if this is the last page
  bool get isLastPage => currentPage == totalPages;
}

/// Represents a filter for log entries.
class LogFilter {
  /// Filter by log level (optional)
  final LogLevel? level;

  /// Filter by tag (optional)
  final String? tag;

  /// Filter by profile ID (optional)
  final String? profileId;

  /// Filter by peer ID (optional)
  final String? peerId;

  /// Filter by start date (optional)
  final DateTime? startDate;

  /// Filter by end date (optional)
  final DateTime? endDate;

  /// Filter by search query in message (optional)
  final String? searchQuery;

  /// Whether the search should be case sensitive
  final bool caseSensitive;

  const LogFilter({
    this.level,
    this.tag,
    this.profileId,
    this.peerId,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.caseSensitive = false,
  });

  /// Creates a copy of this filter with some fields replaced
  LogFilter copyWith({
    LogLevel? level,
    String? tag,
    String? profileId,
    String? peerId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool? caseSensitive,
  }) {
    return LogFilter(
      level: level ?? this.level,
      tag: tag ?? this.tag,
      profileId: profileId ?? this.profileId,
      peerId: peerId ?? this.peerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      caseSensitive: caseSensitive ?? this.caseSensitive,
    );
  }

  /// Returns true if this filter has any criteria set
  bool get hasCriteria =>
      level != null ||
      tag != null ||
      profileId != null ||
      peerId != null ||
      startDate != null ||
      endDate != null ||
      searchQuery != null;
}

/// Supported formats for exporting logs.
enum LogExportFormat {
  /// JSON format
  json,

  /// CSV format
  csv,

  /// Plain text format
  txt,

  /// Logcat format (for Android)
  logcat,
}

/// Represents log statistics.
class LogStatistics {
  /// Total number of log entries
  final int totalEntries;

  /// Number of entries by log level
  final Map<LogLevel, int> entriesByLevel;

  /// Number of entries by tag
  final Map<String, int> entriesByTag;

  /// Number of entries by profile
  final Map<String, int> entriesByProfile;

  /// Timestamp of the oldest log entry
  final DateTime? oldestEntry;

  /// Timestamp of the newest log entry
  final DateTime? newestEntry;

  /// Average number of logs per day
  final double averageLogsPerDay;

  const LogStatistics({
    required this.totalEntries,
    required this.entriesByLevel,
    required this.entriesByTag,
    required this.entriesByProfile,
    this.oldestEntry,
    this.newestEntry,
    required this.averageLogsPerDay,
  });

  /// Returns the most common log level
  LogLevel? get mostCommonLevel {
    if (entriesByLevel.isEmpty) return null;
    return entriesByLevel.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Returns the most common tag
  String? get mostCommonTag {
    if (entriesByTag.isEmpty) return null;
    return entriesByTag.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Returns the duration covered by the logs
  Duration? get duration {
    if (oldestEntry == null || newestEntry == null) return null;
    return newestEntry!.difference(oldestEntry!);
  }
}
