import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geoappbeta/Model/reporteModel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Reporteprovider with ChangeNotifier {
  final List<Reporte> _reportes = [];
  List<Reporte> get reportes => _reportes;

  Future<void> fetchReporte() async {
    try {
      final querydata = await Supabase.instance.client.from('Reportes').select()
          as List<dynamic>;
      _reportes.clear();
      _reportes.addAll(querydata.map((item) {
        item['imagen'] =
            Supabase.instance.client.storage.from('imagenes').getPublicUrl(
                  item['imagen'],
                );
        return Reporte.fromMap(item);
      }).toList());
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchReporteForEmail({required String nombre}) async {
    try {
      final querydata = await Supabase.instance.client
          .from('Reportes')
          .select()
          .eq('nombre', nombre);
      if (querydata.isNotEmpty) {
        _reportes.clear();
        _reportes.addAll(querydata.map((item) {
          item['imagen'] =
              Supabase.instance.client.storage.from('imagenes').getPublicUrl(
                    item['imagen'],
                  );
          return Reporte.fromMap(item);
        }).toList());
      } else {
        _reportes.clear();
      }
    } catch (e) {
      print(e);
    }
  }

  static Future<String> Storage({required File foto}) async {
    final path = "public/${Random().nextInt(1000000)}.jpeg";
    final response = await Supabase.instance.client.storage
        .from('imagenes')
        .upload(path, foto, retryAttempts: 3);
    return path;
  }

  Future<void> addReporte(Reporte data) async {
    await Supabase.instance.client.from('Reportes').insert({
      'nombre': data.nombre != '' ? data.nombre : 'Anonimo',
      'imagen': await Storage(foto: File(data.imagen)),
      'latitud': data.latitud,
      'longitud': data.longitud,
      'descripcion': data.descripcion
    });
  }
}
