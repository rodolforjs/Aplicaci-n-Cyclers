import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../services/places_service.dart';
import '../services/routes_service.dart';
import '../theme/theme.dart';
import 'map_controls.dart';
import 'record_panel.dart';
import 'route_map.dart';
import 'trip_metrics.dart';
import 'turn_card.dart';

// pantalla "Ruta comenzada": el mismo mapa con el recorrido
class TripView extends StatelessWidget {
  const TripView({
    super.key,
    required this.destino,
    required this.origen,
    required this.ruta,
  });

  final Lugar destino;
  final LatLng origen;
  final RutaCalculada ruta;

  // alto aproximado del panel de abajo, para que la ruta no quede tapada
  static const double _altoPanel = 240;

  // relieve y ver todo el recorrido
  static const List<IconData> _herramientas = [
    Icons.terrain,
    Icons.zoom_out_map,
  ];

  @override
  Widget build(BuildContext context) {
    final (restante, unidadRestante) = ruta.distancia;

    return Scaffold(
      body: Stack(
        children: [
          // mapa con el recorrido
          Positioned.fill(
            child: MapaRuta(
              destino: destino.posicion,
              origen: origen,
              puntos: ruta.puntos,
              margenInferior: _altoPanel,
            ),
          ),

          // hacia dónde vas
          Align(
            alignment: Alignment.topCenter,

            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.md),

                child: PointerInterceptor(
                  child: TurnCard(distance: 'Destino', street: destino.nombre),
                ),
              ),
            ),
          ),

          // herramientas + registro
          Align(
            alignment: Alignment.bottomCenter,

            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                Align(
                  alignment: Alignment.centerRight,

                  child: Padding(
                    padding: const EdgeInsets.all(AppPadding.md),

                    child: MapControls(
                      icons: _herramientas,
                      onPressed: (index) {},
                    ),
                  ),
                ),

                PointerInterceptor(
                  child: RecordPanel(
                    time: '00:00',

                    metrics: [
                      const TripMetric(
                        value: '0',
                        unit: 'km/h',
                        label: 'Velocidad',
                      ),
                      const TripMetric(
                        value: '0',
                        unit: 'mts',
                        label: 'Recorrido',
                      ),
                      TripMetric(
                        value: restante,
                        unit: unidadRestante,
                        label: 'Restante',
                      ),
                    ],

                    onPause: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
