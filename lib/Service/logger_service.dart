import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  final _supabase = Supabase.instance.client;

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
      if (kDebugMode) {
        print('Log registrado: $action - $details');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al registrar log: $e');
      }
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
} 