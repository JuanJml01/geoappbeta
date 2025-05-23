// ignore_for_file: file_names
import 'package:flutter/material.dart';

// Categorías predefinidas para tipos de problemas ambientales
class TipoReporteTag {
  final String id;
  final String nombre;
  final IconData icono;

  const TipoReporteTag({
    required this.id,
    required this.nombre,
    required this.icono,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TipoReporteTag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Categorías predefinidas para tipos de ubicaciones
class UbicacionTag {
  final String id;
  final String nombre;
  final IconData icono;

  const UbicacionTag({
    required this.id,
    required this.nombre,
    required this.icono,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UbicacionTag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Modelo para calificaciones de reportes
class ReporteCalificacion {
  final int id;
  final int reporteId;
  final String? userId;
  final String? email;
  final String? deviceId;
  final int calificacion;
  final String? comentario;
  final DateTime createdAt;
  
  ReporteCalificacion({
    this.id = 0,
    required this.reporteId,
    this.userId,
    this.email,
    this.deviceId,
    required this.calificacion,
    this.comentario,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  factory ReporteCalificacion.fromMap(Map<String, dynamic> data) {
    return ReporteCalificacion(
      id: data['id'] is int ? data['id'] : int.tryParse(data['id']?.toString() ?? '0') ?? 0,
      reporteId: data['reporte_id'] is int ? data['reporte_id'] : int.tryParse(data['reporte_id']?.toString() ?? '0') ?? 0,
      userId: data['user_id']?.toString(),
      email: data['email'],
      deviceId: data['device_id'],
      calificacion: data['calificacion'] is int ? data['calificacion'] : int.tryParse(data['calificacion']?.toString() ?? '1') ?? 1,
      comentario: data['comentario'],
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'reporte_id': reporteId,
      'user_id': userId,
      'email': email,
      'device_id': deviceId,
      'calificacion': calificacion,
      'comentario': comentario,
    };
  }
}

// Enums antiguos (mantenidos para compatibilidad)
enum TipoReporte { basura, vandalismo, fauna, agua, aire, ruido, otro }
enum EstadoReporte { pendiente, enProceso, resuelto, cancelado }

String tipoReporteToString(TipoReporte tipo) {
  switch (tipo) {
    case TipoReporte.basura:
      return 'Basura';
    case TipoReporte.vandalismo:
      return 'Vandalismo';
    case TipoReporte.fauna:
      return 'Fauna';
    case TipoReporte.agua:
      return 'Agua';
    case TipoReporte.aire:
      return 'Aire';
    case TipoReporte.ruido:
      return 'Ruido';
    case TipoReporte.otro:
      return 'Otro';
  }
}

String estadoReporteToString(EstadoReporte estado) {
  switch (estado) {
    case EstadoReporte.pendiente:
      return 'Pendiente';
    case EstadoReporte.enProceso:
      return 'En proceso';
    case EstadoReporte.resuelto:
      return 'Resuelto';
    case EstadoReporte.cancelado:
      return 'Cancelado';
  }
}

TipoReporte tipoReporteFromString(String tipo) {
  switch (tipo.toLowerCase()) {
    case 'basura':
      return TipoReporte.basura;
    case 'vandalismo':
      return TipoReporte.vandalismo;
    case 'fauna':
      return TipoReporte.fauna;
    case 'agua':
      return TipoReporte.agua;
    case 'aire':
      return TipoReporte.aire;
    case 'ruido':
      return TipoReporte.ruido;
    default:
      return TipoReporte.otro;
  }
}

EstadoReporte estadoReporteFromString(String estado) {
  switch (estado.toLowerCase()) {
    case 'pendiente':
      return EstadoReporte.pendiente;
    case 'en proceso':
    case 'en_proceso':
      return EstadoReporte.enProceso;
    case 'resuelto':
      return EstadoReporte.resuelto;
    case 'cancelado':
      return EstadoReporte.cancelado;
    default:
      return EstadoReporte.pendiente;
  }
}

// Lista predefinida de tags de tipos de problemas ambientales
final List<TipoReporteTag> tiposReporteTags = [
  TipoReporteTag(id: 'basura', nombre: 'Basura', icono: Icons.delete),
  TipoReporteTag(id: 'vandalismo', nombre: 'Vandalismo', icono: Icons.broken_image),
  TipoReporteTag(id: 'fauna', nombre: 'Fauna', icono: Icons.pets),
  TipoReporteTag(id: 'agua', nombre: 'Agua', icono: Icons.water_drop),
  TipoReporteTag(id: 'aire', nombre: 'Aire', icono: Icons.air),
  TipoReporteTag(id: 'ruido', nombre: 'Ruido', icono: Icons.volume_up),
  TipoReporteTag(id: 'vegetacion', nombre: 'Vegetación', icono: Icons.nature),
  TipoReporteTag(id: 'contaminacion', nombre: 'Contaminación', icono: Icons.cloud),
  TipoReporteTag(id: 'deforestacion', nombre: 'Deforestación', icono: Icons.forest),
  TipoReporteTag(id: 'otro', nombre: 'Otro', icono: Icons.more_horiz),
];

// Lista predefinida de tags de tipos de ubicaciones
final List<UbicacionTag> ubicacionTags = [
  UbicacionTag(id: 'parque', nombre: 'Parque', icono: Icons.park),
  UbicacionTag(id: 'calle', nombre: 'Calle', icono: Icons.add_road),
  UbicacionTag(id: 'playa', nombre: 'Playa', icono: Icons.beach_access),
  UbicacionTag(id: 'rio', nombre: 'Río', icono: Icons.waves),
  UbicacionTag(id: 'bosque', nombre: 'Bosque', icono: Icons.forest),
  UbicacionTag(id: 'zona_urbana', nombre: 'Zona Urbana', icono: Icons.location_city),
  UbicacionTag(id: 'zona_rural', nombre: 'Zona Rural', icono: Icons.grass),
  UbicacionTag(id: 'escuela', nombre: 'Escuela', icono: Icons.school),
  UbicacionTag(id: 'plaza', nombre: 'Plaza', icono: Icons.category),
  UbicacionTag(id: 'otro', nombre: 'Otro Lugar', icono: Icons.pin_drop),
];

// Obtener un tag por su ID
TipoReporteTag getTipoReporteTagById(String id) {
  return tiposReporteTags.firstWhere(
    (tag) => tag.id == id,
    orElse: () => tiposReporteTags.last, // Devuelve 'Otro' si no se encuentra
  );
}

UbicacionTag getUbicacionTagById(String id) {
  return ubicacionTags.firstWhere(
    (tag) => tag.id == id,
    orElse: () => ubicacionTags.last, // Devuelve 'Otro Lugar' si no se encuentra
  );
}

class Reporte {
  final int id;
  final String email;
  final String descripcion;
  final String imagen;
  final double latitud;
  final double longitud;
  final String? userId; // ID del usuario que creó el reporte (puede ser nulo)
  
  // Campos actualizados para usar múltiples tags
  final List<String> tipoTagIds;
  final List<String> ubicacionTagIds;
  
  // Mantenemos los campos anteriores para compatibilidad
  final TipoReporte tipo;
  final EstadoReporte estado;
  final DateTime createdAt;
  
  // Nuevos campos de analítica y priorización
  final int importancia;
  final int vistas;
  final bool prioridadComunidad;
  final List<ReporteCalificacion> calificaciones;
  final double calificacionPromedio;

  Reporte({
    this.id = 0,
    required this.email,
    required this.imagen,
    required this.longitud,
    required this.latitud,
    this.descripcion = "",
    this.tipoTagIds = const ['otro'],
    this.ubicacionTagIds = const ['otro'],
    this.tipo = TipoReporte.otro,
    this.estado = EstadoReporte.pendiente,
    this.userId,
    this.importancia = 0,
    this.vistas = 0,
    this.prioridadComunidad = false,
    this.calificaciones = const [],
    this.calificacionPromedio = 0.0,
    DateTime? createdAt
  }) : createdAt = createdAt ?? DateTime.now();

  // Getters para obtener objetos de tags a partir de los IDs
  List<TipoReporteTag> get tipoTags => 
      tipoTagIds.map((id) => getTipoReporteTagById(id)).toList();
  
  List<UbicacionTag> get ubicacionTags => 
      ubicacionTagIds.map((id) => getUbicacionTagById(id)).toList();
  
  // Obtener el número total de calificaciones
  int get totalCalificaciones => calificaciones.length;

  // Método de fábrica para la conversión desde mapa
  factory Reporte.fromMap(Map<String, dynamic> data) {
    // Procesamiento de tags
    List<String> tipoTagIds = [];
    List<String> ubicacionTagIds = [];
    
    // Intentar extraer tags de tipo
    if (data['tipo_tags'] != null) {
      if (data['tipo_tags'] is List) {
        tipoTagIds = List<String>.from(data['tipo_tags']);
      } else if (data['tipo_tags'] is String) {
        // Si es una cadena separada por comas
        tipoTagIds = (data['tipo_tags'] as String).split(',').where((s) => s.isNotEmpty).toList();
      }
    } else if (data['tipo'] != null) {
      // Compatibilidad con el campo antiguo
      tipoTagIds = [data['tipo'].toString().toLowerCase()];
    } else {
      tipoTagIds = ['otro'];
    }
    
    // Intentar extraer tags de ubicación
    if (data['ubicacion_tags'] != null) {
      if (data['ubicacion_tags'] is List) {
        ubicacionTagIds = List<String>.from(data['ubicacion_tags']);
      } else if (data['ubicacion_tags'] is String) {
        // Si es una cadena separada por comas
        ubicacionTagIds = (data['ubicacion_tags'] as String).split(',').where((s) => s.isNotEmpty).toList();
      }
    } else {
      ubicacionTagIds = ['otro'];
    }
    
    // Asegurarse de que id sea un entero
    int idValue = 0;
    if (data['id'] != null) {
      idValue = data['id'] is int ? data['id'] : int.tryParse(data['id'].toString()) ?? 0;
    }
    
    // Valores por defecto para latitud y longitud
    double lat = 0.0;
    double lng = 0.0;
    
    if (data['latitud'] != null) {
      lat = data['latitud'] is double ? data['latitud'] : double.tryParse(data['latitud'].toString()) ?? 0.0;
    }
    
    if (data['longitud'] != null) {
      lng = data['longitud'] is double ? data['longitud'] : double.tryParse(data['longitud'].toString()) ?? 0.0;
    }
    
    // Manejar los nuevos campos
    int importancia = data['importancia'] is int ? data['importancia'] : int.tryParse(data['importancia']?.toString() ?? '0') ?? 0;
    int vistas = data['vistas'] is int ? data['vistas'] : int.tryParse(data['vistas']?.toString() ?? '0') ?? 0;
    bool prioridadComunidad = data['prioridad_comunidad'] is bool ? data['prioridad_comunidad'] : (data['prioridad_comunidad']?.toString() == 'true');
    
    // Manejar calificación promedio si viene de la vista
    double calificacionPromedio = 0.0;
    if (data['calificacion_promedio'] != null) {
      calificacionPromedio = data['calificacion_promedio'] is double ? 
          data['calificacion_promedio'] : 
          double.tryParse(data['calificacion_promedio']?.toString() ?? '0.0') ?? 0.0;
    }
    
    // Lista de calificaciones (normalmente estaría vacía al cargar de la BD, se llenaría con otra consulta)
    List<ReporteCalificacion> calificaciones = [];
    
    return Reporte(
      id: idValue,
      latitud: lat,
      longitud: lng,
      email: data['email'] ?? '',
      imagen: data['imagen'] ?? '',
      descripcion: data['descripcion'] ?? '',
      tipoTagIds: tipoTagIds,
      ubicacionTagIds: ubicacionTagIds,
      tipo: tipoReporteFromString(data['tipo']?.toString() ?? ''),
      estado: estadoReporteFromString(data['estado']?.toString() ?? ''),
      userId: data['user_id']?.toString(),
      importancia: importancia,
      vistas: vistas,
      prioridadComunidad: prioridadComunidad,
      calificaciones: calificaciones,
      calificacionPromedio: calificacionPromedio,
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : DateTime.now()
    );
  }
  
  // Convertir a Map para enviar a la base de datos
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'latitud': latitud,
      'longitud': longitud,
      'imagen': imagen,
      'descripcion': descripcion,
      'tipo_tags': tipoTagIds.join(','),
      'ubicacion_tags': ubicacionTagIds.join(','),
      'tipo': tipoTagIds.isNotEmpty ? tipoTagIds.first : 'otro', // Para compatibilidad
      'estado': estadoReporteToString(estado),
      'user_id': userId,
      'importancia': importancia,
      'vistas': vistas,
      'prioridad_comunidad': prioridadComunidad,
    };
  }
  
  // Crear una copia del reporte con valores actualizados
  Reporte copyWith({
    int? id,
    String? email,
    String? descripcion,
    String? imagen,
    double? latitud,
    double? longitud,
    String? userId,
    List<String>? tipoTagIds,
    List<String>? ubicacionTagIds,
    TipoReporte? tipo,
    EstadoReporte? estado,
    DateTime? createdAt,
    int? importancia,
    int? vistas,
    bool? prioridadComunidad,
    List<ReporteCalificacion>? calificaciones,
    double? calificacionPromedio,
  }) {
    return Reporte(
      id: id ?? this.id,
      email: email ?? this.email,
      descripcion: descripcion ?? this.descripcion,
      imagen: imagen ?? this.imagen,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      userId: userId ?? this.userId,
      tipoTagIds: tipoTagIds ?? this.tipoTagIds,
      ubicacionTagIds: ubicacionTagIds ?? this.ubicacionTagIds,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      importancia: importancia ?? this.importancia,
      vistas: vistas ?? this.vistas,
      prioridadComunidad: prioridadComunidad ?? this.prioridadComunidad,
      calificaciones: calificaciones ?? this.calificaciones,
      calificacionPromedio: calificacionPromedio ?? this.calificacionPromedio,
    );
  }
}
