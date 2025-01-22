import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

enum FotoAceptada { si, no }

class TomarFoto {
  File? _foto;
  late FotoAceptada _aceptada;

  File? get foto => _foto;
  FotoAceptada get aceptada => FotoAceptada.si;

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
        generationConfig:
            GenerationConfig(responseMimeType: 'application/json'));

    final prompt = TextPart(
        "Si la imagen cumple algunas siguintes condiciones tienes que responder si o no:\n-En la imagen se ve lo siguiente: basura y calle\n-En la imagen se ve lo siguiente: reciclaje, calle y basuro\n-En la imagen se ve lo siguiente: Desechos, calle, basura");
    final imageBytes = await foto.readAsBytes();
    final imageParts = DataPart('image/jpeg', imageBytes);

    final response = await model.generateContent([
      Content.multi([prompt, imageParts])
    ]);
    if (response.text != null) {
      response.text == "si" && response.text == "Si"
          ? _aceptada = FotoAceptada.si
          : _aceptada = FotoAceptada.no;
    } else {
      throw Exception("Error en escanera la imagen");
    }
  }
}
