// Servicio para verificar la configuración de la aplicación
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geoappbeta/Service/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfigService {
  // Verificar la configuración de variables de entorno
  static Future<bool> verificarVariablesEntorno() async {
    bool configuracionValida = true;
    
    // Verificar SUPABASE_URL
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      LoggerService.error('SUPABASE_URL no está configurado en el archivo .env');
      configuracionValida = false;
    } else {
      // Verificar si la URL es correcta (debe contener supabase.co)
      if (!supabaseUrl.contains('supabase.co')) {
        LoggerService.error('SUPABASE_URL no parece ser una URL válida de Supabase');
        configuracionValida = false;
      } else {
        LoggerService.log('SUPABASE_URL configurado correctamente');
      }
    }
    
    // Verificar SUPABASE_KEY
    final supabaseKey = dotenv.env['SUPABASE_KEY'];
    if (supabaseKey == null || supabaseKey.isEmpty) {
      LoggerService.error('SUPABASE_KEY no está configurado en el archivo .env');
      configuracionValida = false;
    } else {
      LoggerService.log('SUPABASE_KEY configurado');
    }
    
    // Verificar webClientId
    final webClientId = dotenv.env['webClientId'];
    if (webClientId == null || webClientId.isEmpty) {
      LoggerService.error('webClientId no está configurado en el archivo .env');
      configuracionValida = false;
    } else {
      // Verificar si el ID tiene el formato correcto
      if (!webClientId.contains('.apps.googleusercontent.com')) {
        LoggerService.error('webClientId no parece tener el formato correcto de Google');
        configuracionValida = false;
      } else {
        LoggerService.log('webClientId configurado');
      }
    }
    
    // Verificar apiKey
    final apiKey = dotenv.env['apiKey'];
    if (apiKey == null || apiKey.isEmpty) {
      LoggerService.error('apiKey no está configurado en el archivo .env');
      configuracionValida = false;
    } else {
      LoggerService.log('apiKey configurado');
    }
    
    return configuracionValida;
  }
  
  // Verificar la conexión con Supabase
  static Future<bool> verificarConexionSupabase() async {
    try {
      LoggerService.log('Verificando conexión con Supabase...');
      
      // Primero verificar si la URL es correcta
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      if (supabaseUrl == null || !supabaseUrl.contains('supabase.co')) {
        LoggerService.warning('La URL de Supabase parece incorrecta, podría ser la URL del dashboard en lugar de la API');
        LoggerService.warning('URL esperada debe contener: supabase.co');
        return false;
      }
      
      // Intentar una operación simple que no requiera autenticación
      try {
        // Simplemente verificar si el cliente está inicializado
        final client = Supabase.instance.client;
        LoggerService.log('Cliente Supabase inicializado correctamente');
        
        // Intentar obtener la sesión actual (no requiere autenticación)
        final session = client.auth.currentSession;
        LoggerService.log('Sesión actual: ${session != null ? "activa" : "inactiva"}');
        
        return true;
      } catch (e) {
        LoggerService.error('Error al verificar cliente Supabase: $e');
        return false;
      }
    } catch (e) {
      LoggerService.error('Error al conectar con Supabase: $e');
      return false;
    }
  }
  
  // Verificar la configuración de autenticación de Google en Supabase
  static Future<bool> verificarConfiguracionGoogleAuth() async {
    try {
      LoggerService.log('Verificando configuración de autenticación de Google...');
      
      // No podemos verificar directamente la configuración de autenticación
      // desde el cliente, así que solo verificamos que las variables estén configuradas
      final webClientId = dotenv.env['webClientId'];
      final apiKey = dotenv.env['apiKey'];
      
      if (webClientId == null || webClientId.isEmpty) {
        LoggerService.error('webClientId no está configurado');
        return false;
      }
      
      if (apiKey == null || apiKey.isEmpty) {
        LoggerService.error('apiKey no está configurado');
        return false;
      }
      
      // Verificar si el webClientId tiene el formato correcto
      if (!webClientId.contains('.apps.googleusercontent.com')) {
        LoggerService.warning('webClientId no parece tener el formato correcto para Google Auth');
        return false;
      }
      
      LoggerService.log('Variables para Google Auth configuradas correctamente');
      return true;
    } catch (e) {
      LoggerService.error('Error al verificar la configuración de autenticación: $e');
      return false;
    }
  }
} 