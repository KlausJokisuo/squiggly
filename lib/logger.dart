import 'dart:io';

class Logger {
  final String logFilePath;
  final IOSink _sink;

  Logger(this.logFilePath)
    : _sink = File(logFilePath).openWrite(mode: FileMode.append);

  void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';

    // Write to file
    _sink.writeln(logEntry);

    // Also print to console
    print(logEntry);
  }

  void error(String message) {
    log('ERROR: $message');
  }

  void info(String message) {
    log('INFO: $message');
  }

  void debug(String message) {
    log('DEBUG: $message');
  }

  Future<void> close() async {
    await _sink.flush();
    await _sink.close();
  }
}
