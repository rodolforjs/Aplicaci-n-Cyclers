import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';

class RutaCalculada {
  const RutaCalculada({
    required this.metros,
    required this.duracion,
    required this.puntos,
  });

  final int metros;
  final Duration duracion;
  final List<LatLng> puntos;

  // (valor, unidad): "2.7 km" o "850 m"
  (String, String) get distancia {
    if (metros >= 1000) return ((metros / 1000).toStringAsFixed(1), 'km');
    return ('$metros', 'm');
  }

  // (valor, unidad): "23 min" o "1:05 h"
  (String, String) get tiempo {
    final minutos = (duracion.inSeconds / 60).ceil();
    if (minutos < 60) return ('$minutos', 'min');
    final resto = (minutos % 60).toString().padLeft(2, '0');
    return ('${minutos ~/ 60}:$resto', 'h');
  }

  // hora de llegada si se sale ahora, "10:05"
  String get llegada {
    final hora = DateTime.now().add(duracion);
    return '${hora.hour.toString().padLeft(2, '0')}:'
        '${hora.minute.toString().padLeft(2, '0')}';
  }
}

class RoutesService {
  Future<RutaCalculada> calcular(LatLng origen, LatLng destino) async {
    Map<String, dynamic> punto(LatLng p) => {
      'location': {
        'latLng': {'latitude': p.latitude, 'longitude': p.longitude},
      },
    };

    final respuesta = await http.post(
      Uri.https('routes.googleapis.com', '/directions/v2:computeRoutes'),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': kPlacesApiKey,
        'X-Goog-FieldMask':
            'routes.duration,routes.distanceMeters,'
            'routes.polyline.encodedPolyline',
      },
      body: jsonEncode({
        'origin': punto(origen),
        'destination': punto(destino),
        'travelMode': 'BICYCLE',
        'languageCode': 'es',
        'units': 'METRIC',
      }),
    );
    if (respuesta.statusCode != 200) {
      throw Exception('Routes ${respuesta.statusCode}: ${respuesta.body}');
    }

    final datos =
        jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    final rutas = datos['routes'] as List<dynamic>? ?? [];
    if (rutas.isEmpty) throw Exception('Routes: sin ruta entre los puntos');

    final ruta = rutas.first as Map<String, dynamic>;
    // la duración llega como texto, por ejemplo "975s"
    final segundos =
        double.tryParse(
          (ruta['duration'] as String? ?? '0s').replaceAll('s', ''),
        ) ??
        0;
    final codigo =
        (ruta['polyline'] as Map<String, dynamic>)['encodedPolyline'] as String;

    return RutaCalculada(
      metros: (ruta['distanceMeters'] as num?)?.toInt() ?? 0,
      duracion: Duration(seconds: segundos.round()),
      puntos: _decodificar(codigo),
    );
  }

  // formato "encoded polyline" de Google: cada punto es la diferencia con el anterior
  static List<LatLng> _decodificar(String codigo) {
    final puntos = <LatLng>[];
    var indice = 0;
    var lat = 0;
    var lng = 0;

    int siguiente() {
      var desplazamiento = 0;
      var resultado = 0;
      int byte;
      do {
        byte = codigo.codeUnitAt(indice++) - 63;
        resultado |= (byte & 0x1f) << desplazamiento;
        desplazamiento += 5;
      } while (byte >= 0x20);
      return (resultado & 1) != 0 ? -((resultado + 1) >> 1) : (resultado >> 1);
    }

    while (indice < codigo.length) {
      lat += siguiente();
      lng += siguiente();
      puntos.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return puntos;
  }
}
