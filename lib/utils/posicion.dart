import 'package:geolocator/geolocator.dart';

class Posicion {
  static Future<Position> getPosition() async {
    Position position = await Geolocator.getCurrentPosition();
    return position;
  }
}
