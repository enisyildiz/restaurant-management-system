import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class LoggerService {
  static final LoggerService instance = LoggerService._init();

  LoggerService._init();

  Future<void> log(String level, String message) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String logsDirPath = join(appDocDir.path, 'RestaurantApp', 'Logs');
      
      final Directory logsDir = Directory(logsDirPath);
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      final String today = DateTime.now().toIso8601String().split('T')[0];
      final String logFilePath = join(logsDirPath, 'log_$today.txt');
      final File logFile = File(logFilePath);

      final String timestamp = DateTime.now().toIso8601String();
      final String logEntry = '[$timestamp] [$level] $message\n';

      // Log hem dosyaya hem de konsola yazdırılır
      print(logEntry.trim());
      await logFile.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      print('Logger error: $e');
    }
  }

  Future<void> info(String message) => log('INFO', message);
  Future<void> error(String message) => log('ERROR', message);
  Future<void> warning(String message) => log('WARN', message);
}
