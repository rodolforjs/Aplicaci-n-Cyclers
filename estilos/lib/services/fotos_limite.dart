import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'places_service.dart';

// Las fotos de Google son lo único que cuesta: gratis hasta 1.000 al mes.
// Este control se queda siempre por debajo de ese tope:
//  - una sola foto por lugar
//  - un lugar ya visto en esta sesión no vuelve a contar
//  - tope por sesión y tope mensual compartido por todos los usuarios
//    (un contador en Firestore, colección "limites")
class LimiteFotos {
  static const int _maximoMensual = 800;
  static const int _maximoPorSesion = 40;

  static int _usadasEnSesion = 0;
  static final Set<String> _aprobadas = {};

  static Future<Lugar> aplicar(Lugar lugar) async {
    final nombre = lugar.fotoNombre;
    if (nombre == null) return lugar;

    if (await _permitir(nombre)) {
      return lugar.conFoto(PlacesService.urlFoto(nombre));
    }
    return lugar;
  }

  static Future<bool> _permitir(String foto) async {
    if (_aprobadas.contains(foto)) return true;
    if (_usadasEnSesion >= _maximoPorSesion) return false;

    final ahora = DateTime.now().toUtc();
    final mes = '${ahora.year}_${ahora.month.toString().padLeft(2, '0')}';
    final ref = FirebaseFirestore.instance
        .collection('limites')
        .doc('fotos_$mes');

    try {
      final permitido = await FirebaseFirestore.instance.runTransaction<bool>((
        transaccion,
      ) async {
        final doc = await transaccion.get(ref);
        final usadas = (doc.data()?['usadas'] as num?)?.toInt() ?? 0;
        if (usadas >= _maximoMensual) return false;
        transaccion.set(ref, {'usadas': usadas + 1});
        return true;
      });

      if (permitido) {
        _usadasEnSesion++;
        _aprobadas.add(foto);
      }
      return permitido;
    } catch (e) {
      debugPrint('No se pudo contar la foto: $e');
      return false;
    }
  }
}
