// ignore_for_file: file_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geoappbeta/Service/logger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum FotoAceptada { si, no }

class TomarFoto {
  final supabase = Supabase.instance.client;
  XFile? _foto;
  String? _url;
  late FotoAceptada _aceptada;

  XFile? get foto => _foto;
  String? get url => _url;
  FotoAceptada get aceptada => _aceptada;

  set foto(XFile? value) => _foto = value;
  set url(String? value) => _url = value;

  Future<void> camara() async {
    final ImagePicker picker = ImagePicker();
    _foto = await picker.pickImage(source: ImageSource.camera);
  }

  Future<void> scanearFoto({required XFile foto}) async {
    try {
      final bytes = await foto.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'reportes/$fileName';

      await supabase.storage.from('imagenes').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      final imageUrl = supabase.storage.from('imagenes').getPublicUrl(path);

      // Registrar el log de la subida de imagen
      await LoggerService().logImageUpload(
        imageUrl: imageUrl,
        reportId: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      this.foto = foto;
      this.url = imageUrl;

      final apikeys = dotenv.env['apiKey'] ?? "";
      final model = GenerativeModel(
        apiKey: apikeys,
        model: 'gemini-2.0-flash',
      );

      final prompt = TextPart(
          """Classify the image content. Respond with 'si' if the image contains any of the following combinations of items, and 'no' otherwise:
- basura y calle
- reciclaje, calle y basura
- Desechos, calle, basura
Provide only the classification ('si' or 'no'). Do not include any other words, descriptions, or explanations.
Valid responses are:
si
no""");
      final imageBytes = await foto.readAsBytes();
      final imageParts = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imageParts])
      ]);
      if (response.text != null) {
        debugPrint(response.text);
        response.text == "si" || response.text == "Si"
            ? _aceptada = FotoAceptada.si
            : _aceptada = FotoAceptada.no;
      } else {
        throw Exception("Error en escanera la imagen");
      }
    } catch (e) {
      throw Exception('Error al escanear la foto: $e');
    }
  }
}
