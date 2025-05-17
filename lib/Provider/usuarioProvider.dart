// ignore_for_file: file_names

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geoappbeta/Model/usuarioModel.dart';
import 'package:geoappbeta/Service/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class UsuarioProvider extends ChangeNotifier {
  // Instancia de Supabase
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Usuario actual
  Usuario? _usuarioActual;
  Usuario? get usuarioActual => _usuarioActual;
  
  // Indica si estamos en modo anónimo
  bool _modoAnonimo = true;
  bool get modoAnonimo => _modoAnonimo;
  
  // Lista de logros disponibles
  List<Logro> _logros = [];
  List<Logro> get logros => _logros;
  
  // Lista de zonas disponibles
  List<ZonaInteres> _zonas = [];
  List<ZonaInteres> get zonas => _zonas;
  
  // Inicializar el provider
  Future<void> inicializar() async {
    // Intentar recuperar la sesión de usuario si existe
    final User? user = _supabase.auth.currentUser;
    
    if (user != null) {
      await _cargarUsuarioAutenticado(user.id);
    } else {
      await _cargarUsuarioAnonimo();
    }
    
    // Cargar logros y zonas disponibles
    await _cargarLogros();
    await _cargarZonas();
    
    notifyListeners();
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
  
  // Cargar usuario autenticado
  Future<void> _cargarUsuarioAutenticado(String userId) async {
    try {
      _modoAnonimo = false;
      LoggerService.log('Cargando perfil de usuario autenticado...');
      
      // Obtener datos del usuario
      final data = await _supabase
        .from('usuarios')
        .select()
        .eq('id', userId)
        .single();
      
      if (data != null) {
        // Cargar logros del usuario
        final logrosData = await _supabase
          .from('usuario_logros')
          .select('*, logro:logro_id(*)')
          .eq('usuario_id', userId);
        
        List<Logro> logrosUsuario = [];
        if (logrosData != null) {
          for (var item in logrosData) {
            var logroMap = item['logro'];
            if (logroMap != null) {
              logrosUsuario.add(Logro.fromMap(logroMap, fechaObtenido: item['fecha_obtenido'] != null 
                  ? DateTime.parse(item['fecha_obtenido']) 
                  : DateTime.now()));
            }
          }
        }
        
        // Cargar zonas del usuario
        final zonasData = await _supabase
          .from('usuario_zonas')
          .select('*, zona:zona_id(*)')
          .eq('usuario_id', userId);
        
        List<ZonaInteres> zonasUsuario = [];
        if (zonasData != null) {
          for (var item in zonasData) {
            zonasUsuario.add(ZonaInteres.fromMap(
              item,
              esFavorita: item['es_favorita'] ?? false,
              esVigilante: item['es_vigilante'] ?? false,
            ));
          }
        }
        
        // Cargar reportes en seguimiento
        final seguimientoData = await _supabase
          .from('reportes_seguimiento')
          .select('*')
          .eq('user_id', userId);
        
        List<ReporteSeguimiento> reportesSeguimiento = [];
        if (seguimientoData != null) {
          reportesSeguimiento = (seguimientoData as List)
            .map((item) => ReporteSeguimiento.fromMap(item))
            .toList();
        }
        
        // Crear objeto usuario
        _usuarioActual = Usuario.fromMap(
          data, 
          logros: logrosUsuario, 
          zonas: zonasUsuario,
          reportesSeguimiento: reportesSeguimiento,
        );
        LoggerService.log('✅ Usuario autenticado cargado: ${_usuarioActual?.nombre}');
      } else {
        // El usuario está autenticado pero no tiene perfil, crear uno
        await _crearPerfilUsuario(userId, _supabase.auth.currentUser?.email ?? 'usuario');
      }
    } catch (e) {
      LoggerService.error('❌ Error al cargar usuario autenticado: $e');
      // Crear usuario anónimo en caso de error
      await _cargarUsuarioAnonimo();
    }
  }
  
  // Crear un perfil para un usuario autenticado
  Future<void> _crearPerfilUsuario(String userId, String nombre) async {
    try {
      final data = {
        'id': userId,
        'nombre': nombre,
        'es_anonimo': false,
        'nivel': 1,
        'puntos': 0,
      };
      
      await _supabase.from('usuarios').insert(data);
      
      // Cargar el perfil recién creado
      await _cargarUsuarioAutenticado(userId);
    } catch (e) {
      LoggerService.error('❌ Error al crear perfil de usuario: $e');
    }
  }
  
  // Cargar usuario anónimo
  Future<void> _cargarUsuarioAnonimo() async {
    _modoAnonimo = true;
    
    // Obtener o generar un ID de dispositivo
    String deviceId = await _obtenerDeviceId();
    
    try {
      // Intentar recuperar usuario anónimo guardado en preferencias
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? anonUserJson = prefs.getString('anon_user');
      
      if (anonUserJson != null) {
        // Aquí se podría deserializar el JSON a un objeto Usuario
        // Por simplicidad, usamos un usuario anónimo nuevo
        _usuarioActual = Usuario.anonimo();
      } else {
        // Crear nuevo usuario anónimo
        _usuarioActual = Usuario.anonimo();
        // Aquí se podría serializar a JSON y guardar
      }
      
      LoggerService.log('✅ Usuario anónimo listo: ${_usuarioActual?.nombre}');
    } catch (e) {
      LoggerService.error('❌ Error con usuario anónimo: $e');
      // Asegurar que siempre haya un usuario disponible
      _usuarioActual = Usuario.anonimo();
    }
  }
  
  // Cargar todos los logros disponibles
  Future<void> _cargarLogros() async {
    try {
      final data = await _supabase
        .from('logros')
        .select('*')
        .order('nivel_requerido', ascending: true);
      
      _logros = data.map<Logro>((item) => Logro.fromMap(item)).toList();
      LoggerService.log('✅ ${_logros.length} logros cargados');
    } catch (e) {
      LoggerService.error('❌ Error al cargar logros: $e');
    }
  }
  
  // Cargar todas las zonas disponibles
  Future<void> _cargarZonas() async {
    try {
      final data = await _supabase
        .from('zonas')
        .select('*');
      
      _zonas = data.map<ZonaInteres>((item) => ZonaInteres.fromMap(item)).toList();
      LoggerService.log('✅ ${_zonas.length} zonas cargadas');
    } catch (e) {
      LoggerService.error('❌ Error al cargar zonas: $e');
    }
  }
  
  // Actualizar el perfil del usuario
  Future<bool> actualizarPerfil({
    String? nombre,
    String? ciudad,
    String? bio,
    String? foto,
  }) async {
    if (_usuarioActual == null || modoAnonimo) {
      LoggerService.error('❌ No se puede actualizar perfil: usuario anónimo o no inicializado');
      return false;
    }
    
    try {
      final datos = {
        if (nombre != null) 'nombre': nombre,
        if (ciudad != null) 'ciudad': ciudad,
        if (bio != null) 'bio': bio,
        if (foto != null) 'foto': foto,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await _supabase
        .from('usuarios')
        .update(datos)
        .eq('id', _usuarioActual!.id);
      
      // Actualizar el usuario local
      _usuarioActual = _usuarioActual!.copyWith(
        nombre: nombre,
        ciudad: ciudad,
        bio: bio,
        foto: foto,
        updatedAt: DateTime.now(),
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      LoggerService.error('❌ Error al actualizar perfil: $e');
      return false;
    }
  }
  
  // Subir foto de perfil
  Future<String?> subirFotoPerfil(File foto) async {
    if (_usuarioActual == null || modoAnonimo) {
      return null;
    }
    
    try {
      final fileName = 'perfil_${_usuarioActual!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _supabase.storage
        .from('perfiles')
        .upload(fileName, foto);
      
      // Obtener URL pública
      final urlResponse = _supabase.storage
        .from('perfiles')
        .getPublicUrl(fileName);
      
      return urlResponse;
    } catch (e) {
      LoggerService.error('❌ Error al subir foto: $e');
      return null;
    }
  }
  
  // Calificar un reporte
  Future<bool> calificarReporte(int reporteId, int calificacion, {String? comentario}) async {
    try {
      String email;
      String? userId;
      
      if (_usuarioActual == null) {
        email = 'anonymous_${await _obtenerDeviceId()}';
        userId = null;
      } else if (modoAnonimo) {
        email = 'anonymous_${await _obtenerDeviceId()}';
        userId = null;
      } else {
        email = _usuarioActual!.nombre;
        userId = _usuarioActual!.id;
      }
      
      final deviceId = await _obtenerDeviceId();
      
      // Verificar si ya calificó este reporte desde este dispositivo
      final existente = await _supabase
        .from('reporte_calificaciones')
        .select('id')
        .or('device_id.eq.$deviceId,user_id.eq.$userId')
        .eq('reporte_id', reporteId)
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
      } else {
        // Insertar nueva calificación
        await _supabase
          .from('reporte_calificaciones')
          .insert({
            'reporte_id': reporteId,
            'user_id': userId,
            'email': email,
            'device_id': deviceId,
            'calificacion': calificacion,
            'comentario': comentario,
          });
      }
      
      return true;
    } catch (e) {
      LoggerService.error('❌ Error al calificar reporte: $e');
      return false;
    }
  }
  
  // Marcar una zona como favorita
  Future<bool> marcarZonaFavorita(int zonaId, bool esFavorita) async {
    if (_usuarioActual == null || modoAnonimo) {
      return false;
    }
    
    try {
      // Verificar si ya existe relación con esta zona
      final existente = await _supabase
        .from('usuario_zonas')
        .select('id')
        .eq('usuario_id', _usuarioActual!.id)
        .eq('zona_id', zonaId)
        .maybeSingle();
      
      if (existente != null) {
        // Actualizar relación existente
        await _supabase
          .from('usuario_zonas')
          .update({
            'es_favorita': esFavorita,
          })
          .eq('id', existente['id']);
      } else {
        // Crear nueva relación
        await _supabase
          .from('usuario_zonas')
          .insert({
            'usuario_id': _usuarioActual!.id,
            'zona_id': zonaId,
            'es_favorita': esFavorita,
            'es_vigilante': false,
          });
      }
      
      // Recargar perfil del usuario para actualizar zonas
      await _cargarUsuarioAutenticado(_usuarioActual!.id);
      notifyListeners();
      
      return true;
    } catch (e) {
      LoggerService.error('❌ Error al marcar zona como favorita: $e');
      return false;
    }
  }
  
  // Agregar un reporte al seguimiento
  Future<bool> agregarReporteSeguimiento(int reporteId, {String? notas}) async {
    try {
      if (_usuarioActual == null) {
        LoggerService.error('No se puede agregar reporte a seguimiento: usuario no inicializado');
        return false;
      }
      
      if (modoAnonimo) {
        LoggerService.error('No se puede agregar reporte a seguimiento: usuario anónimo');
        return false;
      }
      
      // Verificar si ya está siguiendo este reporte
      final existente = await _supabase
        .from('reportes_seguimiento')
        .select('id')
        .eq('user_id', _usuarioActual!.id)
        .eq('reporte_id', reporteId)
        .maybeSingle();
      
      if (existente != null) {
        // Ya está siguiendo este reporte, actualizar notas si es necesario
        if (notas != null) {
          await _supabase
            .from('reportes_seguimiento')
            .update({'notas': notas})
            .eq('id', existente['id']);
        }
        return true;
      }
      
      // Insertar nuevo seguimiento
      await _supabase
        .from('reportes_seguimiento')
        .insert({
          'reporte_id': reporteId,
          'user_id': _usuarioActual!.id,
          'notas': notas,
        });
      
      // Actualizar la lista local de reportes en seguimiento
      final nuevoSeguimiento = ReporteSeguimiento(
        id: 0, // ID temporal, se actualizará en la próxima carga
        reporteId: reporteId,
        userId: _usuarioActual!.id,
        fechaAdicion: DateTime.now(),
        notas: notas,
      );
      
      final reportesSeguimiento = List<ReporteSeguimiento>.from(_usuarioActual!.reportesSeguimiento);
      reportesSeguimiento.add(nuevoSeguimiento);
      
      _usuarioActual = _usuarioActual!.copyWith(
        reportesSeguimiento: reportesSeguimiento,
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      LoggerService.error('❌ Error al agregar reporte a seguimiento: $e');
      return false;
    }
  }
  
  // Eliminar un reporte del seguimiento
  Future<bool> eliminarReporteSeguimiento(int reporteId) async {
    try {
      if (_usuarioActual == null || modoAnonimo) {
        LoggerService.error('No se puede eliminar reporte de seguimiento: usuario no inicializado o anónimo');
        return false;
      }
      
      // Eliminar de la base de datos
      await _supabase
        .from('reportes_seguimiento')
        .delete()
        .eq('user_id', _usuarioActual!.id)
        .eq('reporte_id', reporteId);
      
      // Actualizar la lista local
      final reportesSeguimiento = _usuarioActual!.reportesSeguimiento
        .where((r) => r.reporteId != reporteId)
        .toList();
      
      _usuarioActual = _usuarioActual!.copyWith(
        reportesSeguimiento: reportesSeguimiento,
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      LoggerService.error('❌ Error al eliminar reporte de seguimiento: $e');
      return false;
    }
  }
  
  // Verificar si un reporte está en seguimiento
  bool estaEnSeguimiento(int reporteId) {
    if (_usuarioActual == null || modoAnonimo) {
      return false;
    }
    
    return _usuarioActual!.reportesSeguimiento.any((r) => r.reporteId == reporteId);
  }
  
  // Cargar reportes en seguimiento
  Future<void> cargarReportesSeguimiento() async {
    try {
      if (_usuarioActual == null || modoAnonimo) {
        return;
      }
      
      final data = await _supabase
        .from('reportes_seguimiento')
        .select('*')
        .eq('user_id', _usuarioActual!.id);
      
      if (data != null) {
        final reportesSeguimiento = (data as List)
          .map((item) => ReporteSeguimiento.fromMap(item))
          .toList();
        
        _usuarioActual = _usuarioActual!.copyWith(
          reportesSeguimiento: reportesSeguimiento,
        );
        
        notifyListeners();
      }
    } catch (e) {
      LoggerService.error('❌ Error al cargar reportes en seguimiento: $e');
    }
  }
  
  // Votar por la prioridad de un reporte
  Future<bool> votarPrioridadReporte(int reporteId, bool esPrioritario) async {
    try {
      String? userId;
      String deviceId;
      
      if (_usuarioActual == null || modoAnonimo) {
        deviceId = await _obtenerDeviceId();
        userId = null;
      } else {
        deviceId = await _obtenerDeviceId();
        userId = _usuarioActual!.id;
      }
      
      // Verificar si ya votó
      final existente = await _supabase
        .from('reporte_prioridad_votos')
        .select('id')
        .or('device_id.eq.$deviceId,user_id.eq.$userId')
        .eq('reporte_id', reporteId)
        .maybeSingle();
      
      if (existente != null) {
        // Actualizar voto existente
        await _supabase
          .from('reporte_prioridad_votos')
          .update({
            'es_prioritario': esPrioritario,
          })
          .eq('id', existente['id']);
      } else {
        // Insertar nuevo voto
        await _supabase
          .from('reporte_prioridad_votos')
          .insert({
            'reporte_id': reporteId,
            'user_id': userId,
            'device_id': deviceId,
            'es_prioritario': esPrioritario,
          });
      }
      
      return true;
    } catch (e) {
      LoggerService.error('❌ Error al votar por prioridad: $e');
      return false;
    }
  }
  
  // Iniciar sesión con email y contraseña
  Future<bool> iniciarSesion(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        await _cargarUsuarioAutenticado(response.user!.id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('❌ Error al iniciar sesión: $e');
      return false;
    }
  }
  
  // Registrar nuevo usuario
  Future<bool> registrarse(String email, String password, String nombre) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nombre': nombre,
        }
      );
      
      if (response.user != null) {
        // El trigger en la base de datos debería crear el perfil,
        // pero por si acaso, intentamos crearlo también aquí
        await _crearPerfilUsuario(response.user!.id, nombre);
        await _cargarUsuarioAutenticado(response.user!.id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('❌ Error al registrarse: $e');
      return false;
    }
  }
  
  // Cerrar sesión
  Future<void> cerrarSesion() async {
    try {
      await _supabase.auth.signOut();
      await _cargarUsuarioAnonimo();
      notifyListeners();
    } catch (e) {
      LoggerService.error('❌ Error al cerrar sesión: $e');
    }
  }
} 