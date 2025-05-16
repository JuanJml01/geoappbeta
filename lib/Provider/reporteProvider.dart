// ignore_for_file: file_names

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geoappbeta/Model/reporteModel.dart';
import 'package:geoappbeta/Service/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Reporteprovider extends ChangeNotifier {
  final List<Reporte> _reportes = [];
  List<Reporte> get reportes => _reportes;

  // Reportes filtrados por importancia/prioridad
  List<Reporte> get reportesPrioritarios => 
      _reportes.where((r) => r.prioridadComunidad || r.importancia > 5).toList();
  
  // Reportes ordenados por calificación promedio
  List<Reporte> get reportesPopulares => 
      [..._reportes]..sort((a, b) => b.calificacionPromedio.compareTo(a.calificacionPromedio));

  // Instancia de Supabase
  final SupabaseClient _supabase = Supabase.instance.client;

  // Nombres correctos de tabla y bucket en Supabase (¡importante respetar mayúsculas!)
  final String _table = 'Reportes'; // La tabla existe como "Reportes" con R mayúscula
  final String _bucket = 'imagenes'; // Nombre del bucket verificado
  
  // Estado de carga
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Mensaje de error
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Obtener todos los reportes
  Future<void> fetchReporte() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      LoggerService.log('🔄 Intentando obtener reportes de la tabla $_table...');
      
      // Primera opción: intentar usar la vista que incluye calificaciones
      try {
        final data = await _supabase
            .from('reportes_con_calificaciones')
            .select('*')
            .order('importancia', ascending: false);
            
        _reportes.clear();
        for (final item in data) {
          _reportes.add(Reporte.fromMap(item));
        }
        
        LoggerService.log('✅ ${_reportes.length} reportes obtenidos con calificaciones');
      } catch (e) {
        // Si falla la vista, usar la tabla directa
        LoggerService.warning('⚠️ Error al usar vista: $e. Intentando con tabla directa...');
        
        final data = await _supabase
            .from(_table)
            .select('*')
            .order('importancia', ascending: false);
            
        _reportes.clear();
        for (final item in data) {
          _reportes.add(Reporte.fromMap(item));
        }
        
        // Obtener calificaciones por separado
        await _cargarCalificaciones();
        
        LoggerService.log('✅ ${_reportes.length} reportes obtenidos con carga manual de calificaciones');
      }
    } catch (e) {
      LoggerService.error('❌ Error al obtener reportes: $e');
      _errorMessage = 'Error al cargar reportes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Obtener reportes por email del usuario
  Future<void> fetchReporteForEmail({required String nombre}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      LoggerService.log('🔄 Buscando reportes para el email: $nombre');
      
      final data = await _supabase
          .from(_table)
          .select('*')
          .eq('email', nombre)
          .order('created_at', ascending: false);
          
      _reportes.clear();
      for (final item in data) {
        _reportes.add(Reporte.fromMap(item));
      }
      
      // Cargar calificaciones
      await _cargarCalificaciones();
      
      LoggerService.log('✅ ${_reportes.length} reportes encontrados para $nombre');
    } catch (e) {
      LoggerService.error('❌ Error al obtener reportes por email: $e');
      _errorMessage = 'Error al cargar tus reportes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Cargar calificaciones para los reportes (si no se usó la vista)
  Future<void> _cargarCalificaciones() async {
    try {
      if (_reportes.isEmpty) return;
      
      // Obtener IDs de reportes para la consulta
      final List<int> ids = _reportes.map((r) => r.id).toList();
      
      // Obtener calificaciones agrupadas por reporte
      final data = await _supabase
          .from('reporte_calificaciones')
          .select('reporte_id, calificacion')
          .inFilter('reporte_id', ids);
      
      // Mapa de reporteId -> [calificaciones]
      final Map<int, List<int>> calificacionesPorReporte = {};
      
      // Agrupar calificaciones por reporte
      for (final item in data) {
        final reporteId = item['reporte_id'];
        final calificacion = item['calificacion'];
        
        if (reporteId != null && calificacion != null) {
          if (!calificacionesPorReporte.containsKey(reporteId)) {
            calificacionesPorReporte[reporteId] = [];
          }
          calificacionesPorReporte[reporteId]!.add(calificacion);
        }
      }
      
      // Calcular promedios y actualizar reportes
      for (int i = 0; i < _reportes.length; i++) {
        final reporte = _reportes[i];
        final calificaciones = calificacionesPorReporte[reporte.id] ?? [];
        
        if (calificaciones.isNotEmpty) {
          double promedio = calificaciones.reduce((a, b) => a + b) / calificaciones.length;
          
          // Crear copia actualizada del reporte
          _reportes[i] = reporte.copyWith(
            calificacionPromedio: promedio,
            // Crear objetos ReporteCalificacion simplificados
            calificaciones: calificaciones.map((c) => 
              ReporteCalificacion(
                reporteId: reporte.id,
                calificacion: c
              )
            ).toList(),
          );
        }
      }
      
      LoggerService.log('✅ Calificaciones cargadas para ${calificacionesPorReporte.length} reportes');
    } catch (e) {
      LoggerService.error('❌ Error al cargar calificaciones: $e');
    }
  }

  // Añadir un nuevo reporte
  Future<bool> addReporte(Reporte reporte) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      LoggerService.log('🔄 Añadiendo nuevo reporte...');
      
      // Subir la imagen
      String? imageUrl = await _subirImagen(File(reporte.imagen));
      if (imageUrl == null) {
        _errorMessage = 'Error al subir la imagen';
        return false;
      }
      
      // Actualizar el reporte con la URL de la imagen
      final reporteActualizado = reporte.copyWith(imagen: imageUrl);
      
      // Insertar en la base de datos
      await _supabase.from(_table).insert(reporteActualizado.toMap());
      
      // Añadir a la lista local de reportes
      _reportes.add(reporteActualizado);
      
      LoggerService.log('✅ Reporte añadido correctamente');
      return true;
    } catch (e) {
      LoggerService.error('❌ Error al añadir reporte: $e');
      _errorMessage = 'Error al añadir reporte: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Subir un nuevo reporte
  Future<bool> subirReporte(Reporte reporte, File imagen) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      LoggerService.log('🔄 Iniciando subida de reporte...');
      
      // 1. Subir la imagen al storage
      String? imageUrl = await _subirImagen(imagen);
      if (imageUrl == null) {
        _errorMessage = 'Error al subir la imagen';
        return false;
      }
      
      // 2. Crear el reporte con la URL de la imagen
      final reporteConImagen = reporte.copyWith(imagen: imageUrl);
      
      // 3. Insertar en la base de datos
      await _supabase.from(_table).insert(reporteConImagen.toMap());
      
      // 4. Refrescar la lista de reportes
      await fetchReporte();
      
      LoggerService.log('✅ Reporte subido correctamente');
      return true;
    } catch (e) {
      LoggerService.error('❌ Error al subir reporte: $e');
      _errorMessage = 'Error al subir reporte: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Calificar un reporte
  Future<bool> calificarReporte(int reporteId, int calificacion, {String? comentario, String? email, String? userId}) async {
    try {
      LoggerService.log('🔄 Calificando reporte $reporteId con $calificacion estrellas...');
      
      // Obtener ID de dispositivo para usuarios anónimos
      String deviceId = await _obtenerDeviceId();
      
      // Verificar si este dispositivo ya calificó el reporte
      final existente = await _supabase
        .from('reporte_calificaciones')
        .select('id')
        .eq('reporte_id', reporteId)
        .eq('device_id', deviceId)
        .maybeSingle();
      
      if (existente != null) {
        // Actualizar calificación existente
        await _supabase
          .from('reporte_calificaciones')
          .update({
            'calificacion': calificacion,
            'comentario': comentario,
          })
          .eq('id', existente['id']);
          
        LoggerService.log('✅ Calificación actualizada');
      } else {
        // Insertar nueva calificación
        await _supabase
          .from('reporte_calificaciones')
          .insert({
            'reporte_id': reporteId,
            'user_id': userId,
            'email': email ?? 'anonymous_$deviceId',
            'device_id': deviceId,
            'calificacion': calificacion,
            'comentario': comentario,
          });
          
        LoggerService.log('✅ Nueva calificación añadida');
      }
      
      // Refrescar reportes para mostrar nueva calificación
      await fetchReporte();
      return true;
    } catch (e) {
      LoggerService.error('❌ Error al calificar reporte: $e');
      return false;
    }
  }
  
  // Incrementar vistas de un reporte
  Future<void> incrementarVistas(int reporteId) async {
    try {
      // Llamar a la función de la base de datos
      await _supabase.rpc('incrementar_vistas_reporte', params: {
        'p_reporte_id': reporteId
      });
      
      // Actualizar el reporte localmente
      final index = _reportes.indexWhere((r) => r.id == reporteId);
      if (index >= 0) {
        _reportes[index] = _reportes[index].copyWith(
          vistas: _reportes[index].vistas + 1
        );
        notifyListeners();
      }
    } catch (e) {
      // No mostrar error al usuario
      LoggerService.warning('⚠️ Error al incrementar vistas: $e');
    }
  }
  
  // Marcar reporte como prioritario
  Future<bool> marcarPrioritario(int reporteId, bool esPrioritario) async {
    try {
      await _supabase
        .from(_table)
        .update({
          'prioridad_comunidad': esPrioritario
        })
        .eq('id', reporteId);
      
      // Actualizar reporte localmente
      final index = _reportes.indexWhere((r) => r.id == reporteId);
      if (index >= 0) {
        _reportes[index] = _reportes[index].copyWith(
          prioridadComunidad: esPrioritario
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      LoggerService.error('❌ Error al marcar reporte como prioritario: $e');
      return false;
    }
  }
  
  // Obtener reportes cercanos a una ubicación
  Future<List<Reporte>> obtenerReportesCercanos(double lat, double lng, double radioKm) async {
    try {
      LoggerService.log('🔄 Buscando reportes cercanos a $lat, $lng en radio de $radioKm km...');
      
      // Usar la función RPC para obtener reportes cercanos
      final data = await _supabase.rpc('get_reportes_cercanos', params: {
        'lat': lat,
        'lng': lng,
        'radio_km': radioKm
      });
      
      final reportesCercanos = data.map<Reporte>((item) => Reporte.fromMap(item)).toList();
      LoggerService.log('✅ ${reportesCercanos.length} reportes cercanos encontrados');
      
      return reportesCercanos;
    } catch (e) {
      LoggerService.error('❌ Error al obtener reportes cercanos: $e');
      
      // Usar un cálculo de distancia en memoria si falla la función RPC
      return _reportes.where((r) {
        final distancia = _calcularDistanciaGeo(lat, lng, r.latitud, r.longitud);
        return distancia <= radioKm;
      }).toList();
    }
  }
  
  // Cálculo simple de distancia en kilómetros (fórmula de Haversine)
  double _calcularDistanciaGeo(double lat1, double lon1, double lat2, double lon2) {
    const radioTierra = 6371.0; // Radio de la Tierra en km
    
    // Convertir a radianes
    final dLat = _toRadianes(lat2 - lat1);
    final dLon = _toRadianes(lon2 - lon1);
    
    // Fórmula de Haversine
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadianes(lat1)) * cos(_toRadianes(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return radioTierra * c;
  }
  
  double _toRadianes(double grados) {
    return grados * pi / 180;
  }
  
  // Obtener un ID de dispositivo para usuarios anónimos
  Future<String> _obtenerDeviceId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('device_id');
      
      if (deviceId == null) {
        // Generar un ID aleatorio para este dispositivo
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
        await prefs.setString('device_id', deviceId);
      }
      
      return deviceId;
    } catch (e) {
      // En caso de error, generar un ID aleatorio temporal
      return 'temp_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Subir una imagen al storage
  Future<String?> _subirImagen(File image) async {
    try {
      const int maxRetries = 3;
      int intentos = 0;
      String? imageUrl;
      
      while (intentos < maxRetries && imageUrl == null) {
        intentos++;
        try {
          final String fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          await _supabase.storage
              .from(_bucket)
              .upload(fileName, image);
              
          // Obtener URL pública
          imageUrl = _supabase.storage
              .from(_bucket)
              .getPublicUrl(fileName);
              
          LoggerService.log('✅ Imagen subida con éxito en el intento $intentos: $imageUrl');
          return imageUrl;
        } catch (e) {
          LoggerService.warning('⚠️ Error en intento $intentos: $e');
          await Future.delayed(Duration(seconds: 1 * intentos)); // Esperar más tiempo en cada reintento
        }
      }
      
      if (imageUrl == null) {
        throw Exception('No se pudo subir la imagen después de $maxRetries intentos');
      }
      
      return imageUrl;
    } catch (e) {
      LoggerService.error('❌ Error al subir imagen: $e');
      return null;
    }
  }
}
