// ignore_for_file: file_names

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geoapptest/Model/reporteModel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Reporteprovider extends ChangeNotifier {
  final List<Reporte> _reportes = [];
  List<Reporte> get reportes => _reportes;

  // Instancia de Supabase
  final SupabaseClient _supabase = Supabase.instance.client;

  // Nombres correctos de tabla y bucket en Supabase (¡importante respetar mayúsculas!)
  final String _table = 'Reportes'; // La tabla existe como "Reportes" con R mayúscula
  final String _bucket = 'imagenes'; // Nombre del bucket verificado

  Future<void> fetchReporte() async {
    try {
      debugPrint('🔄 Intentando obtener reportes de la tabla $_table...');
      final data = await _supabase.from(_table).select('*');
      _reportes.clear();
      
      debugPrint('✅ Reportes obtenidos: ${data.length}');
      
      for (final item in data) {
        // Si la imagen no tiene URL completa, construirla
        if (item['imagen'] != null && !item['imagen'].toString().startsWith('http')) {
          item['imagen'] = _supabase.storage.from(_bucket).getPublicUrl(item['imagen']);
        }
        _reportes.add(Reporte.fromMap(item));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error al obtener reportes: $e');
      // Intentar recuperarse del error, pero no relanzarlo para evitar que la app se bloquee
      _reportes.clear();
      notifyListeners();
    }
  }

  Future<void> fetchReporteForEmail({required String nombre}) async {
    try {
      debugPrint('🔄 Buscando reportes para el email: $nombre');
      final data = await _supabase
          .from(_table)
          .select('*')
          .eq('email', nombre);
      
      _reportes.clear();
      
      for (final item in data) {
        // Si la imagen no tiene URL completa, construirla
        if (item['imagen'] != null && !item['imagen'].toString().startsWith('http')) {
          item['imagen'] = _supabase.storage.from(_bucket).getPublicUrl(item['imagen']);
        }
        _reportes.add(Reporte.fromMap(item));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error al obtener reportes por email: $e');
      // No relanzar el error para evitar que la app se bloquee
      _reportes.clear();
      notifyListeners();
    }
  }

  Future<bool> addReporte(Reporte reporte) async {
    try {
      // Mostrar en consola que estamos subiendo la imagen
      debugPrint('📤 Iniciando carga de imagen...');
      
      // Verificar permisos antes de subir
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null && !reporte.email.contains('anonymous')) {
        debugPrint('❌ Error de permisos: Usuario no autenticado y no es anónimo');
        return false;
      }
      
      // Subir la imagen primero
      String? imagePath = await _subirImagen(reporte.imagen);
      
      if (imagePath == null) {
        debugPrint('❌ Error al subir la imagen: no se pudo obtener la ruta');
        return false;
      }
      
      debugPrint('✅ Imagen subida correctamente: $imagePath');
      
      // Preparar los datos para la base de datos
      Map<String, dynamic> reporteData = {
        'email': reporte.email,
        'latitud': reporte.latitud,
        'longitud': reporte.longitud,
        'imagen': imagePath, // Ahora guardamos solo la ruta, no la URL completa
        'descripcion': reporte.descripcion,
        'tipo': reporte.tipoTagIds.isNotEmpty ? reporte.tipoTagIds.first : 'otro', // Para compatibilidad
        'estado': 'pendiente',
        'tipo_tags': reporte.tipoTagIds.join(','),
        'ubicacion_tags': reporte.ubicacionTagIds.join(','),
        'created_at': DateTime.now().toIso8601String(),
        // Si el usuario está autenticado, guardar su ID
        'user_id': currentUser?.id,
      };
      
      debugPrint('📝 Enviando datos a la base de datos...');
      
      // Insertar en la base de datos
      final data = await _supabase.from(_table).insert(reporteData).select();
      
      if (data.isNotEmpty) {
        // Añadir la URL completa para la visualización
        if (data[0]['imagen'] != null && !data[0]['imagen'].toString().startsWith('http')) {
          data[0]['imagen'] = _supabase.storage.from(_bucket).getPublicUrl(data[0]['imagen']);
        }
        
        _reportes.add(Reporte.fromMap(data[0]));
        notifyListeners();
        
        debugPrint('✅ Reporte añadido correctamente');
        return true;
      }
      
      debugPrint('⚠️ No se recibió confirmación de la base de datos');
      return false;
    } catch (e) {
      debugPrint('❌ Error al agregar reporte: $e');
      return false;
    }
  }

  Future<String?> _subirImagen(String imagePath) async {
    try {
      final file = File(imagePath);
      
      if (!await file.exists()) {
        debugPrint('❌ El archivo no existe en la ruta proporcionada: $imagePath');
        return null;
      }
      
      // Generar un nombre único para la imagen
      final fileExt = imagePath.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'reportes/$fileName'; // La carpeta dentro del bucket
      
      debugPrint('📤 Subiendo archivo a $filePath...');
      
      // Subir la imagen con reintentos
      int attempts = 0;
      const maxAttempts = 3;
      
      while (attempts < maxAttempts) {
        try {
          await _supabase.storage.from(_bucket).upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true, // Permitir sobrescritura si existe
            ),
          );
          
          debugPrint('✅ Imagen subida exitosamente después de ${attempts + 1} intentos');
          return filePath; // Retornar solo la ruta, no la URL completa
        } catch (uploadError) {
          attempts++;
          debugPrint('⚠️ Intento $attempts fallido: $uploadError');
          
          // Si es un error de permisos, intentar usar una estrategia alternativa
          if (uploadError.toString().contains('row-level security policy') || 
              uploadError.toString().contains('Unauthorized')) {
            
            debugPrint('🔐 Detectado error de permisos, intentando subir con método alternativo...');
            try {
              // Intentar con un método alternativo para usuarios anónimos
              final bytes = await file.readAsBytes();
              await _supabase.storage.from(_bucket).uploadBinary(
                filePath,
                bytes,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                ),
              );
              debugPrint('✅ Imagen subida exitosamente con método alternativo');
              return filePath;
            } catch (altError) {
              debugPrint('❌ Error con método alternativo: $altError');
            }
          }
          
          if (attempts >= maxAttempts) {
            rethrow;
          }
          
          // Esperar antes de reintentar
          await Future.delayed(Duration(seconds: 1 * attempts));
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error al subir imagen: $e');
      return null;
    }
  }
}
