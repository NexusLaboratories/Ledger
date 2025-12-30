import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Production-ready logging service that:
/// - Writes logs to a file for production debugging
/// - Uses console output in debug mode
/// - Automatically manages log file size
/// - Supports log export for user bug reports
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;

  LoggerService._internal();

  static Logger? _logger;
  static File? _logFile;
  static bool _initialized = false;
  static const int _maxLogFileSize = 5 * 1024 * 1024; // 5MB
  static final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  /// Initialize the logger service
  static Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialize logger with file output
      _logger = Logger(
        filter: ProductionFilter(),
        printer: SimplePrinter(colors: false, printTime: true),
        output: _FileOutput(),
      );

      _initialized = true;
    } catch (e) {
      // Fallback to basic logger if file initialization fails
      _logger = Logger(printer: PrettyPrinter());
      _initialized = true;
    }
  }

  /// Log debug message (only in debug mode, not written to file in release)
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!kReleaseMode) {
      _ensureInitialized();
      _logger?.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log info message (written to file in all modes)
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger?.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message (written to file in all modes)
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger?.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message (written to file in all modes)
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger?.e(message, error: error, stackTrace: stackTrace);
  }

  /// Get the current log file for sharing with support
  static Future<File?> getLogFile() async {
    await _ensureLogFileExists();
    return _logFile;
  }

  /// Clear the log file
  static Future<void> clearLogs() async {
    try {
      await _ensureLogFileExists();
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.writeAsString('');
      }
    } catch (e) {
      // Silent fail if we can't clear logs
    }
  }

  /// Get logs as a string for display or sharing
  static Future<String> getLogsAsString() async {
    try {
      await _ensureLogFileExists();
      if (_logFile != null && await _logFile!.exists()) {
        return await _logFile!.readAsString();
      }
    } catch (e) {
      return 'Failed to read log file: $e';
    }
    return 'No logs available';
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      // Synchronous fallback initialization
      _logger = Logger(printer: PrettyPrinter());
      _initialized = true;
    }
  }

  static Future<void> _ensureLogFileExists() async {
    if (_logFile != null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/ledger_logs.txt');

      // Check file size and rotate if needed
      if (await _logFile!.exists()) {
        final fileSize = await _logFile!.length();
        if (fileSize > _maxLogFileSize) {
          // Keep last 1MB of logs
          final content = await _logFile!.readAsString();
          final lines = content.split('\n');
          final keepLines = lines.length > 1000
              ? lines.sublist(lines.length - 1000)
              : lines;
          await _logFile!.writeAsString(keepLines.join('\n'));
        }
      }
    } catch (e) {
      // Can't create log file, logging will go to console only
    }
  }
}

/// Custom file output for logger
class _FileOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // Write to file asynchronously
    _writeToFile(event);

    // Also output to console in debug mode
    if (!kReleaseMode) {
      for (var line in event.lines) {
        // ignore: avoid_print
        print(line);
      }
    }
  }

  Future<void> _writeToFile(OutputEvent event) async {
    try {
      await LoggerService._ensureLogFileExists();
      if (LoggerService._logFile != null) {
        final timestamp = LoggerService._dateFormat.format(DateTime.now());
        final logLines = event.lines
            .map((line) => '[$timestamp] $line')
            .join('\n');
        await LoggerService._logFile!.writeAsString(
          '$logLines\n',
          mode: FileMode.append,
        );
      }
    } catch (e) {
      // Silent fail - logging should never break the app
    }
  }
}
