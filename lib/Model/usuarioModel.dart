// ignore_for_file: file_names
import 'package:flutter/material.dart';

// Modelo para logros del sistema
class Logro {
  final int id;
  final String nombre;
  final String descripcion;
  final String icono;
  final int puntos;
  final String categoria;
  final int nivelRequerido;
  final DateTime? fechaObtenido; // Solo si el usuario ya lo ha conseguido
  
  const Logro({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    this.puntos = 10,
    required this.categoria,
    this.nivelRequerido = 1,
    this.fechaObtenido,
  });
  
  // Si el logro ha sido obtenido
  bool get obtenido => fechaObtenido != null;
  
  // Método para crear un logro a partir de datos de la BD
  factory Logro.fromMap(Map<String, dynamic> data, {DateTime? fechaObtenido}) {
    return Logro(
      id: data['id'] is int ? data['id'] : int.tryParse(data['id']?.toString() ?? '0') ?? 0,
      nombre: data['nombre'] ?? 'Logro sin nombre',
      descripcion: data['descripcion'] ?? '',
      icono: data['icono'] ?? 'emoji_events',
      puntos: data['puntos'] is int ? data['puntos'] : int.tryParse(data['puntos']?.toString() ?? '10') ?? 10,
      categoria: data['categoria'] ?? 'general',
      nivelRequerido: data['nivel_requerido'] is int ? data['nivel_requerido'] : int.tryParse(data['nivel_requerido']?.toString() ?? '1') ?? 1,
      fechaObtenido: fechaObtenido ?? (data['fecha_obtenido'] != null ? DateTime.parse(data['fecha_obtenido']) : null),
    );
  }
  
  // Obtener icono como widget
  IconData get iconoWidget {
    // Intentar convertir el nombre del icono a un IconData
    // Este switch podría expandirse con más iconos según sea necesario
    switch (icono) {
      case 'eco': 
        return Icons.eco;
      case 'shield': 
        return Icons.shield;
      case 'camera': 
        return Icons.camera_alt;
      case 'location_city': 
        return Icons.location_city;
      case 'delete': 
        return Icons.delete;
      case 'thumb_up': 
        return Icons.thumb_up;
      case 'forest': 
        return Icons.forest;
      case 'water': 
        return Icons.water;
      default: 
        return Icons.emoji_events;
    }
  }
  
  // Color según la categoría
  Color get categoriaColor {
    switch (categoria.toLowerCase()) {
      case 'contribución':
        return Colors.blue;
      case 'calidad':
        return Colors.purple;
      case 'comunidad':
        return Colors.green;
      case 'especialización':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }
}

// Modelo para zonas de interés del usuario
class ZonaInteres {
  final int id;
  final String nombre;
  final String? descripcion;
  final double latitud;
  final double longitud;
  final double radioKm;
  final bool esFavorita;
  final bool esVigilante;
  
  const ZonaInteres({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.latitud,
    required this.longitud,
    this.radioKm = 1.0,
    this.esFavorita = false,
    this.esVigilante = false,
  });
  
  factory ZonaInteres.fromMap(Map<String, dynamic> data, {bool esFavorita = false, bool esVigilante = false}) {
    // Si los datos vienen de la tabla de relación, tendrán una estructura anidada
    Map<String, dynamic> zonaData = data;
    if (data['zona_id'] != null && data['zona'] != null) {
      zonaData = data['zona'];
    }
    
    return ZonaInteres(
      id: zonaData['id'] is int ? zonaData['id'] : int.tryParse(zonaData['id']?.toString() ?? '0') ?? 0,
      nombre: zonaData['nombre'] ?? 'Zona sin nombre',
      descripcion: zonaData['descripcion'],
      latitud: zonaData['latitud'] is double ? zonaData['latitud'] : double.tryParse(zonaData['latitud']?.toString() ?? '0') ?? 0,
      longitud: zonaData['longitud'] is double ? zonaData['longitud'] : double.tryParse(zonaData['longitud']?.toString() ?? '0') ?? 0,
      radioKm: zonaData['radio_km'] is double ? zonaData['radio_km'] : double.tryParse(zonaData['radio_km']?.toString() ?? '1.0') ?? 1.0,
      esFavorita: data['es_favorita'] is bool ? data['es_favorita'] : (data['es_favorita']?.toString() == 'true'),
      esVigilante: data['es_vigilante'] is bool ? data['es_vigilante'] : (data['es_vigilante']?.toString() == 'true'),
    );
  }
}

// Modelo principal de Usuario
class Usuario {
  final String id;
  final String nombre;
  final String? ciudad;
  final String? bio;
  final String? foto;
  final int nivel;
  final int puntos;
  final bool esAnonimo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Logro> logros;
  final List<ZonaInteres> zonasInteres;
  
  const Usuario({
    required this.id,
    required this.nombre,
    this.ciudad,
    this.bio,
    this.foto,
    this.nivel = 1,
    this.puntos = 0,
    this.esAnonimo = false,
    required this.createdAt,
    required this.updatedAt,
    this.logros = const [],
    this.zonasInteres = const [],
  });
  
  // Informar si el usuario tiene un perfil básico completo
  bool get tienePerfilCompleto => ciudad != null && bio != null && foto != null;
  
  // Número de logros obtenidos
  int get logrosObtenidos => logros.where((l) => l.obtenido).length;
  
  // Número de zonas favoritas
  int get zonasFavoritas => zonasInteres.where((z) => z.esFavorita).length;
  
  // Número de zonas donde es vigilante
  int get zonasVigiladas => zonasInteres.where((z) => z.esVigilante).length;
  
  // Factory para crear un usuario desde los datos de la BD
  factory Usuario.fromMap(Map<String, dynamic> data, {List<Logro>? logros, List<ZonaInteres>? zonas}) {
    return Usuario(
      id: data['id']?.toString() ?? '',
      nombre: data['nombre'] ?? 'Usuario',
      ciudad: data['ciudad'],
      bio: data['bio'],
      foto: data['foto'],
      nivel: data['nivel'] is int ? data['nivel'] : int.tryParse(data['nivel']?.toString() ?? '1') ?? 1,
      puntos: data['puntos'] is int ? data['puntos'] : int.tryParse(data['puntos']?.toString() ?? '0') ?? 0,
      esAnonimo: data['es_anonimo'] is bool ? data['es_anonimo'] : (data['es_anonimo']?.toString() == 'true'),
      createdAt: data['created_at'] != null ? DateTime.parse(data['created_at']) : DateTime.now(),
      updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : DateTime.now(),
      logros: logros ?? [],
      zonasInteres: zonas ?? [],
    );
  }
  
  // Crear un usuario anónimo
  factory Usuario.anonimo() {
    final String anonId = 'anon_${DateTime.now().millisecondsSinceEpoch}';
    return Usuario(
      id: anonId,
      nombre: 'Usuario Anónimo',
      esAnonimo: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  // Convertir a Map para actualizar en la BD
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'ciudad': ciudad,
      'bio': bio,
      'foto': foto,
      'nivel': nivel,
      'puntos': puntos,
      'es_anonimo': esAnonimo,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
  
  // Crear una copia con valores actualizados
  Usuario copyWith({
    String? id,
    String? nombre,
    String? ciudad,
    String? bio,
    String? foto,
    int? nivel,
    int? puntos,
    bool? esAnonimo,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Logro>? logros,
    List<ZonaInteres>? zonasInteres,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      ciudad: ciudad ?? this.ciudad,
      bio: bio ?? this.bio,
      foto: foto ?? this.foto,
      nivel: nivel ?? this.nivel,
      puntos: puntos ?? this.puntos,
      esAnonimo: esAnonimo ?? this.esAnonimo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      logros: logros ?? this.logros,
      zonasInteres: zonasInteres ?? this.zonasInteres,
    );
  }
} 