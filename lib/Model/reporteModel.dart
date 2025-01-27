// ignore_for_file: file_names

class Reporte {
  final int id;
  final String email;
  final String descripcion;
  final String imagen;
  final double latitud;
  final double longitud;

  Reporte(
      {this.id = 0,
      required this.email,
      required this.imagen,
      required this.longitud,
      required this.latitud,
      this.descripcion = ""});

  factory Reporte.fromMap(Map<String, dynamic> data) {
    return Reporte(
        id: data['id'],
        latitud: data['latitud'],
        longitud: data['longitud'],
        email: data['email'],
        imagen: data['imagen'],
        descripcion: data['descripcion']);
  }
}
