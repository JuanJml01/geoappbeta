// ignore_for_file: file_names

import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

enum FotoAceptada { si, no }

class TomarFoto {
  File? _foto;
  late FotoAceptada _aceptada;

  File? get foto => _foto;
  FotoAceptada get aceptada => _aceptada;

  Future<void> camara() async {
    final ImagePicker picker = ImagePicker();

    final foto = await picker.pickImage(
        source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear);
    if (foto != null) {
      _foto = File(foto.path);
    }
  }

  Future<void> scanearFoto({required File foto}) async {
    final apikeys = dotenv.env['apiKey'] ?? "";
    final model = GenerativeModel(
        apiKey: apikeys,
        model: 'gemini-2.0-flash-exp',
        generationConfig: GenerationConfig());

    final prompt = TextPart(
        "Si la imagen cumple algunas siguintes condiciones tienes que responder si o no:\n-En la imagen se ve lo siguiente: basura y calle\n-En la imagen se ve lo siguiente: reciclaje, calle y basura\n-En la imagen se ve lo siguiente: Desechos, calle, basura");
    final imageBytes = await foto.readAsBytes();
    final imageParts = DataPart('image/jpeg', imageBytes);

    final response = await model.generateContent([
      Content.multi([prompt, imageParts])
    ]);
    
    if (response.text != null) {
      final respuesta = response.text!.toLowerCase();
      _aceptada = (respuesta == "si") ? FotoAceptada.si : FotoAceptada.no;
    } else {
      throw Exception("Error en escanear la imagen");
    }
  }
}
