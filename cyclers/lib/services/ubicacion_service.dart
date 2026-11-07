import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UbicacionException implements Exception {
  const UbicacionException(this.mensaje);

  final String mensaje;
}

class UbicacionService {
  Future<LatLng> actual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const UbicacionException('Activa la ubicación del dispositivo.');
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      throw const UbicacionException(
        'Permite el acceso a tu ubicación para trazar la ruta.',
      );
    }

    try {
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(posicion.latitude, posicion.longitude);
    } catch (_) {
      throw const UbicacionException('No se pudo obtener tu ubicación.');
    }
  }
}
