class Reporte {
  final int id;
  final String nombre;
  final String descripcion;
  final String imagen;
  final double latitud;
  final double longitud;

  Reporte(
      {this.id = 0,
      required this.nombre,
      required this.imagen,
      required this.longitud,
      required this.latitud,
      this.descripcion = ""});

  factory Reporte.fromMap(Map<String, dynamic> data) {
    return Reporte(
        id: data['id'],
        latitud: data['latitud'],
        longitud: data['longitud'],
        nombre: data['nombre'],
        imagen: data['imagen'],
        descripcion: data['descripcion']);
  }
}
