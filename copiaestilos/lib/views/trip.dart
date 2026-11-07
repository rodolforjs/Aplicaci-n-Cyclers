import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'map_background.dart';
import 'map_controls.dart';
import 'record_panel.dart';
import 'trip_metrics.dart';
import 'turn_card.dart';

// pantalla "Ruta comenzada"
class TripView extends StatelessWidget {
  const TripView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // mapa
          const Positioned.fill(child: MapBackground()),

          // instrucción de giro
          Align(
            alignment: Alignment.topCenter,

            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.md),

                child: TurnCard(
                  distance: 'En 200 metros',
                  street: 'Rosas',
                  onExpand: () {},
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
                      icons: routeToolIcons,
                      onPressed: (index) {},
                    ),
                  ),
                ),

                RecordPanel(
                  time: '00:00',

                  metrics: const [
                    TripMetric(value: '10', unit: 'km/h', label: 'Velocidad'),
                    TripMetric(value: '327', unit: 'mts', label: 'Recorrido'),
                    TripMetric(value: '3.2', unit: 'km', label: 'Restante'),
                  ],

                  // pendiente: pantalla "Ruta pausada"
                  onPause: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
