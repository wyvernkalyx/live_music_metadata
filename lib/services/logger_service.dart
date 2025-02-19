import 'package:logger/logger.dart';

class LoggerService {
  static LoggerService? _instance;
  final Logger _logger;

  LoggerService._() : _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static LoggerService get instance {
    _instance ??= LoggerService._();
    return _instance!;
  }

  void info(String message) => _logger.i(message);
  void warning(String message) => _logger.w(message);
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
  void debug(String message) => _logger.d(message);
}
