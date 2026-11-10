import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

// una foto elegida de la galería, todavía sin subir.
// Los bytes se leen una sola vez: sirven para la miniatura y para subirla.
class FotoNueva {
  const FotoNueva({required this.nombre, required this.bytes});

  final String nombre;
  final Uint8List bytes;
}

// una foto ya subida a Storage
class FotoSubida {
  const FotoSubida({required this.url, required this.archivo});

  // para mostrarla (Image.network)
  final String url;
  // ruta dentro de Storage, para poder borrarla después
  final String archivo;
}

// fotos propias del usuario: elegir de la galería y subir a Firebase Storage.
// Se suben como bytes (putData) y no como File, así funciona en Android y en web.
class FotosService {
  static const int maximo = 6;
  static final _picker = ImagePicker();

  // abre la galería; devuelve como mucho "cuantas" fotos
  static Future<List<FotoNueva>> elegir({int cuantas = maximo}) async {
    if (cuantas <= 0) return [];

    final archivos = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1600,
    );

    final fotos = <FotoNueva>[];
    for (final archivo in archivos.take(cuantas)) {
      fotos.add(
        FotoNueva(nombre: archivo.name, bytes: await archivo.readAsBytes()),
      );
    }
    return fotos;
  }

  // sube las fotos a "carpeta/id/" (ej: lugares/abc123/...).
  // Si una falla, borra las que alcanzaron a subir y lanza el error.
  static Future<List<FotoSubida>> subir(
    String carpeta,
    String id,
    List<FotoNueva> fotos,
  ) async {
    final subidas = <FotoSubida>[];
    final momento = DateTime.now().millisecondsSinceEpoch;

    try {
      for (final foto in fotos) {
        final extension = _extension(foto.nombre);
        final ref = FirebaseStorage.instance.ref(
          '$carpeta/$id/${momento}_${subidas.length}.$extension',
        );

        await ref.putData(
          foto.bytes,
          SettableMetadata(contentType: _tipo(extension)),
        );

        subidas.add(
          FotoSubida(url: await ref.getDownloadURL(), archivo: ref.fullPath),
        );
      }
      return subidas;
    } catch (e) {
      await borrar(subidas.map((f) => f.archivo));
      rethrow;
    }
  }

  // borra fotos de Storage; si una no existe, sigue con las demás
  static Future<void> borrar(Iterable<String> archivos) async {
    for (final archivo in archivos) {
      try {
        await FirebaseStorage.instance.ref(archivo).delete();
      } catch (e) {
        debugPrint('No se pudo borrar la foto $archivo: $e');
      }
    }
  }

  static String _extension(String nombre) {
    final partes = nombre.toLowerCase().split('.');
    final extension = partes.length > 1 ? partes.last : '';
    return ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
        ? extension
        : 'jpg';
  }

  static String _tipo(String extension) => switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
