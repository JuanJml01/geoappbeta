// ignore_for_file: file_names
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio de logging centralizado para la aplicación
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  final _supabase = Supabase.instance.client;

  // Niveles de log
  static const int DEBUG = 0;
  static const int INFO = 1;
  static const int WARNING = 2;
  static const int ERROR = 3;
  
  // Nivel actual (configurable)
  static int _currentLevel = DEBUG;
  
  // Cambiar el nivel de registro
  static void setLevel(int level) {
    _currentLevel = level;
  }

  /// Registro de información normal
  static void log(String message) {
    if (_currentLevel <= INFO) {
      print('ℹ️ INFO: $message');
    }
  }

  /// Registro de información de depuración
  static void debug(String message) {
    if (_currentLevel <= DEBUG) {
      print('🔍 DEBUG: $message');
    }
  }

  /// Registro de advertencias
  static void warning(String message) {
    if (_currentLevel <= WARNING) {
      print('⚠️ WARN: $message');
    }
  }

  /// Registro de errores
  static void error(String message) {
    if (_currentLevel <= ERROR) {
      print('❌ ERROR: $message');
    }
  }

  /// Registro de información importante
  static void info(String message) {
    if (_currentLevel <= INFO) {
      print('ℹ️ INFO: $message');
    }
  }

  /// Registro de mensajes de autenticación
  static void auth(String message) {
    print('🔐 AUTH: $message');
  }

  void _printLog(String type, String message, {Map<String, dynamic>? data}) {
    final timestamp = DateTime.now().toString();
    final logMessage = '''
╔════════════════════════════════════════════════════════════════════════════
║ $type - $timestamp
║ $message
${data != null ? '║ Datos adicionales: $data' : ''}
╚════════════════════════════════════════════════════════════════════════════
''';
    debugPrint(logMessage);
  }

  Future<void> logUserAction({
    required String action,
    required String details,
    String? userId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final logData = {
        'action': action,
        'details': details,
        'user_id': userId ?? _supabase.auth.currentUser?.id,
        'timestamp': timestamp,
        'additional_data': additionalData,
      };

      await _supabase.from('user_logs').insert(logData);
      _printLog('ACCION', '$action - $details', data: additionalData);
    } catch (e) {
      _printLog('ERROR', 'Error al registrar log: $e');
    }
  }

  Future<void> logImageUpload({
    required String imageUrl,
    required String reportId,
    String? userId,
  }) async {
    await logUserAction(
      action: 'IMAGE_UPLOAD',
      details: 'Imagen subida exitosamente',
      userId: userId,
      additionalData: {
        'image_url': imageUrl,
        'report_id': reportId,
      },
    );
  }

  Future<void> logMapInteraction({
    required String action,
    required Map<String, dynamic> details,
  }) async {
    await logUserAction(
      action: 'MAP_INTERACTION',
      details: action,
      additionalData: details,
    );
  }
} 