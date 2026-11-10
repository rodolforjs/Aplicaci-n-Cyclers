import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// mapa real con el recorrido dibujado: tu ubicación, el destino y la ruta
class MapaRuta extends StatefulWidget {
  const MapaRuta({
    super.key,
    required this.destino,
    this.origen,
    this.puntos = const [],
    this.tipo = MapType.normal,
    this.margenInferior = 0,
  });

  final LatLng destino;
  final LatLng? origen;
  final List<LatLng> puntos;
  final MapType tipo;

  // alto aproximado de la card que tapa la parte de abajo del mapa
  final double margenInferior;

  @override
  State<MapaRuta> createState() => MapaRutaState();
}

class MapaRutaState extends State<MapaRuta> {
  static const double _margen = 72;
  static const int _grosorRuta = 6;
  static const double _zoomDestino = 15;

  GoogleMapController? _controller;

  @override
  void didUpdateWidget(MapaRuta oldWidget) {
    super.didUpdateWidget(oldWidget);
    // llegó la ruta: se encuadra completa
    if (!identical(oldWidget.puntos, widget.puntos) &&
        widget.puntos.isNotEmpty) {
      ajustar();
    }
  }

  // encuadra todo el recorrido en pantalla
  Future<void> ajustar() async {
    final controller = _controller;
    if (controller == null) return;

    final puntos = widget.puntos.isNotEmpty
        ? widget.puntos
        : [if (widget.origen != null) widget.origen!, widget.destino];

    var sur = puntos.first.latitude;
    var norte = sur;
    var oeste = puntos.first.longitude;
    var este = oeste;
    for (final punto in puntos) {
      sur = math.min(sur, punto.latitude);
      norte = math.max(norte, punto.latitude);
      oeste = math.min(oeste, punto.longitude);
      este = math.max(este, punto.longitude);
    }

    try {
      if (sur == norte && oeste == este) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(widget.destino, _zoomDestino),
        );
        return;
      }
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(sur, oeste),
            northeast: LatLng(norte, este),
          ),
          _margen,
        ),
      );
    } catch (e) {
      debugPrint('No se pudo encuadrar la ruta: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final origen = widget.origen;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: origen ?? widget.destino,
        zoom: _zoomDestino,
      ),
      mapType: widget.tipo,
      padding: EdgeInsets.only(bottom: widget.margenInferior),
      markers: {
        Marker(markerId: const MarkerId('destino'), position: widget.destino),
        if (origen != null)
          Marker(
            markerId: const MarkerId('origen'),
            position: origen,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
      },
      polylines: {
        if (widget.puntos.length > 1)
          Polyline(
            polylineId: const PolylineId('ruta'),
            points: widget.puntos,
            color: colors.primary,
            width: _grosorRuta,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
      },
      onMapCreated: (controller) {
        _controller = controller;
        WidgetsBinding.instance.addPostFrameCallback((_) => ajustar());
      },
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
    );
  }
}
