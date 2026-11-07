import 'dart:convert';
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';

// una sugerencia del autocompletado (todavía sin coordenadas)
class LugarSugerido {
  const LugarSugerido({
    required this.id,
    required this.titulo,
    required this.detalle,
  });

  final String id;
  final String titulo;
  final String detalle;
}

// un lugar ya resuelto, listo para mostrar en el mapa
class Lugar {
  const Lugar({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.posicion,
    this.tipo,
    this.esRuta = false,
    this.idRuta,
    this.fotoNombre,
    this.fotoAutor,
    this.fotoUrl,
  });

  Lugar conFoto(String url) {
    return Lugar(
      id: id,
      nombre: nombre,
      direccion: direccion,
      posicion: posicion,
      tipo: tipo,
      esRuta: esRuta,
      idRuta: idRuta,
      fotoNombre: fotoNombre,
      fotoAutor: fotoAutor,
      fotoUrl: url,
    );
  }

  // una ruta guardada en Firestore, para mostrarla igual que un lugar.
  static Lugar? deRuta(Map<String, dynamic> ruta, [String? idDoc]) {
    final latitud = (ruta['latitud'] as num?)?.toDouble();
    final longitud = (ruta['longitud'] as num?)?.toDouble();
    if (latitud == null || longitud == null) return null;

    final dificultad = ruta['dificultad'] as String?;
    return Lugar(
      id: idDoc ?? 'ruta_${latitud}_$longitud',
      nombre: ruta['titulo'] as String? ?? 'Sin título',
      direccion: ruta['descripcion'] as String? ?? '',
      tipo: dificultad == null ? 'Ruta' : 'Ruta · $dificultad',
      posicion: LatLng(latitud, longitud),
      esRuta: true,
      idRuta: idDoc,
    );
  }

  final String id;
  final String nombre;
  final String direccion;
  final String? tipo;
  final LatLng posicion;
  final bool esRuta;
  // id del documento en Firestore (solo rutas guardadas)
  final String? idRuta;

  // foto que ofrece Google (solo el nombre; no se pide hasta que se apruebe)
  final String? fotoNombre;
  final String? fotoAutor;

  // foto ya aprobada, lista para mostrar
  final String? fotoUrl;
}

// búsqueda de lugares reales con Google Places API (New).
// Funciona igual en Android y en web.
class PlacesService {
  static const String _host = 'places.googleapis.com';

  // la búsqueda favorece lugares cerca de Santiago de Chile
  static const Map<String, double> _centro = {
    'latitude': -33.4489,
    'longitude': -70.6693,
  };
  static const double _radioMetros = 50000;

  // al tocar el mapa solo cuenta un lugar casi exactamente ahí
  static const double _pixelesToque = 30;

  // una "sesión" agrupa las letras que se escriben y la elección final
  // (así Google las cobra como una sola búsqueda)
  static String nuevaSesion() {
    const letras = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final azar = math.Random();
    return List.generate(32, (_) => letras[azar.nextInt(letras.length)]).join();
  }

  Future<List<LugarSugerido>> autocompletar(
    String texto, {
    required String sesion,
  }) async {
    final respuesta = await http.post(
      Uri.https(_host, '/v1/places:autocomplete'),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': kPlacesApiKey,
      },
      body: jsonEncode({
        'input': texto,
        'languageCode': 'es',
        'regionCode': 'CL',
        'sessionToken': sesion,
        'locationBias': {
          'circle': {'center': _centro, 'radius': _radioMetros},
        },
      }),
    );
    if (respuesta.statusCode != 200) {
      throw Exception('Places ${respuesta.statusCode}: ${respuesta.body}');
    }

    final datos =
        jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    final sugerencias = datos['suggestions'] as List<dynamic>? ?? [];

    final resultado = <LugarSugerido>[];
    for (final item in sugerencias) {
      final prediccion =
          (item as Map<String, dynamic>)['placePrediction']
              as Map<String, dynamic>?;
      if (prediccion == null) continue;

      final formato = prediccion['structuredFormat'] as Map<String, dynamic>?;
      final principal = (formato?['mainText'] as Map?)?['text'] as String?;
      final secundario =
          (formato?['secondaryText'] as Map?)?['text'] as String?;
      final completo = (prediccion['text'] as Map?)?['text'] as String? ?? '';

      resultado.add(
        LugarSugerido(
          id: prediccion['placeId'] as String,
          titulo: principal ?? completo,
          detalle: secundario ?? '',
        ),
      );
    }
    return resultado;
  }

  Future<Lugar> detalle(String id, {required String sesion}) async {
    final respuesta = await http.get(
      Uri.https(_host, '/v1/places/$id', {
        'languageCode': 'es',
        'sessionToken': sesion,
      }),
      headers: {
        'X-Goog-Api-Key': kPlacesApiKey,
        'X-Goog-FieldMask':
            'displayName,formattedAddress,location,primaryType,'
            'primaryTypeDisplayName,photos',
      },
    );
    if (respuesta.statusCode != 200) {
      throw Exception('Places ${respuesta.statusCode}: ${respuesta.body}');
    }

    final datos =
        jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    return _lugarDesde(datos, id);
  }

  // lugar real que esté justo donde se tocó el mapa (null si no hay ninguno)
  Future<Lugar?> cercano(LatLng punto, {required double zoom}) async {
    // el radio sigue al zoom: ~20 px alrededor del dedo, pero entre 12 y 40 m
    final metrosPorPixel =
        156543.03392 *
        math.cos(punto.latitude * math.pi / 180) /
        math.pow(2, zoom);
    final radio = (metrosPorPixel * _pixelesToque).clamp(12.0, 40.0);

    final respuesta = await http.post(
      Uri.https(_host, '/v1/places:searchNearby'),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': kPlacesApiKey,
        'X-Goog-FieldMask':
            'places.id,places.displayName,places.formattedAddress,'
            'places.location,places.primaryType,'
            'places.primaryTypeDisplayName,places.photos',
      },
      body: jsonEncode({
        'maxResultCount': 1,
        'rankPreference': 'DISTANCE',
        // los paraderos tapan al lugar que realmente se quiso tocar
        'excludedTypes': ['bus_stop'],
        'languageCode': 'es',
        'locationRestriction': {
          'circle': {
            'center': {
              'latitude': punto.latitude,
              'longitude': punto.longitude,
            },
            'radius': radio,
          },
        },
      }),
    );
    if (respuesta.statusCode != 200) {
      throw Exception('Places ${respuesta.statusCode}: ${respuesta.body}');
    }

    final datos =
        jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    final lugares = datos['places'] as List<dynamic>? ?? [];
    if (lugares.isEmpty) return null;

    final primero = lugares.first as Map<String, dynamic>;
    return _lugarDesde(primero, primero['id'] as String);
  }

  // nombre de la calle en ese punto (Geocoding API); null si no hay calle cerca
  Future<Lugar?> calle(LatLng punto) async {
    final respuesta = await http.get(
      Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '${punto.latitude},${punto.longitude}',
        'language': 'es',
        'result_type': 'route',
        'key': kPlacesApiKey,
      }),
    );
    if (respuesta.statusCode != 200) {
      throw Exception('Geocoding ${respuesta.statusCode}: ${respuesta.body}');
    }

    final datos =
        jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    final estado = datos['status'] as String?;
    if (estado == 'ZERO_RESULTS') return null;
    if (estado != 'OK') {
      throw Exception('Geocoding $estado: ${datos['error_message']}');
    }

    final componentes =
        ((datos['results'] as List).first
                as Map<String, dynamic>)['address_components']
            as List<dynamic>;

    // nombre largo del primer componente que tenga alguno de esos tipos
    String? buscar(List<String> tipos) {
      for (final componente in componentes) {
        final tiposComponente = (componente as Map)['types'] as List<dynamic>;
        if (tipos.any(tiposComponente.contains)) {
          return componente['long_name'] as String?;
        }
      }
      return null;
    }

    final calle = buscar(['route']);
    final comuna = buscar(['locality', 'administrative_area_level_3']);
    final region = buscar(['administrative_area_level_1']);
    if (calle == null) return null;

    return Lugar(
      id: 'calle_${punto.latitude}_${punto.longitude}',
      nombre: calle,
      direccion: [comuna, region].whereType<String>().join(', '),
      tipo: 'Calle',
      posicion: punto,
    );
  }

  // dirección de la imagen (cuenta como una foto en la factura de Google)
  static String urlFoto(String nombre, {int ancho = 640}) {
    return Uri.https(_host, '/v1/$nombre/media', {
      'maxWidthPx': '$ancho',
      'key': kPlacesApiKey,
    }).toString();
  }

  Lugar _lugarDesde(Map<String, dynamic> datos, String id) {
    final ubicacion = datos['location'] as Map<String, dynamic>;

    // solo la primera foto, y con su autor (Google exige mostrarlo)
    final fotos = datos['photos'] as List<dynamic>?;
    final foto = fotos == null || fotos.isEmpty
        ? null
        : fotos.first as Map<String, dynamic>;
    final autores = foto?['authorAttributions'] as List<dynamic>?;
    final autor = autores == null || autores.isEmpty
        ? null
        : (autores.first as Map)['displayName'] as String?;

    return Lugar(
      id: id,
      fotoNombre: foto?['name'] as String?,
      fotoAutor: autor,
      nombre: (datos['displayName'] as Map?)?['text'] as String? ?? '',
      direccion: datos['formattedAddress'] as String? ?? '',
      // "establecimiento" no dice nada: en ese caso la card solo dice "Lugar"
      tipo: _tiposGenericos.contains(datos['primaryType'])
          ? null
          : (datos['primaryTypeDisplayName'] as Map?)?['text'] as String?,
      posicion: LatLng(
        (ubicacion['latitude'] as num).toDouble(),
        (ubicacion['longitude'] as num).toDouble(),
      ),
    );
  }

  static const Set<String> _tiposGenericos = {
    'establishment',
    'point_of_interest',
  };
}
