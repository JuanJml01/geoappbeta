// ignore_for_file: file_names

enum TipoReporte { basura, vandalismo, fauna, agua, aire, ruido, otro }
enum EstadoReporte { pendiente, enProceso, resuelto }

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
      return EstadoReporte.enProceso;
    case 'resuelto':
      return EstadoReporte.resuelto;
    default:
      return EstadoReporte.pendiente;
  }
}

class Reporte {
  final int id;
  final String email;
  final String descripcion;
  final String imagen;
  final double latitud;
  final double longitud;
  final TipoReporte tipo;
  final EstadoReporte estado;
  final DateTime createdAt;

  Reporte(
      {this.id = 0,
      required this.email,
      required this.imagen,
      required this.longitud,
      required this.latitud,
      this.descripcion = "",
      this.tipo = TipoReporte.otro,
      this.estado = EstadoReporte.pendiente,
      DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  factory Reporte.fromMap(Map<String, dynamic> data) {
    return Reporte(
        id: data['id'],
        latitud: data['latitud'],
        longitud: data['longitud'],
        email: data['email'],
        imagen: data['imagen'],
        descripcion: data['descripcion'],
        tipo: tipoReporteFromString(data['tipo'] ?? ''),
        estado: estadoReporteFromString(data['estado'] ?? ''),
        createdAt: data['created_at'] != null ? DateTime.parse(data['created_at']) : DateTime.now());
  }
}
