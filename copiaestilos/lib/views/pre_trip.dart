import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'map_background.dart';
import 'map_controls.dart';
import 'route_card.dart';
import 'trip.dart';
import 'trip_metrics.dart';

// pantalla "Precomienzo Viaje"
class PreTripView extends StatelessWidget {
  const PreTripView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      // app bar
      appBar: AppBar(
        backgroundColor: AppColors.neutral0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,

        title: const Text('Viaje'),

        actions: [
          IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),

          const SizedBox(width: AppPadding.sm),
        ],

        // franja con el recorrido
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),

          child: Container(
            width: double.infinity,
            color: colors.primary,

            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.md,
              vertical: AppPadding.sm,
            ),

            child: Text(
              'Ubicación actual > Santa Lucía',
              style: text.bodyMedium?.copyWith(color: colors.onPrimary),
            ),
          ),
        ),
      ),

      // contenido
      body: Stack(
        children: [
          // mapa
          const Positioned.fill(child: MapBackground()),

          // herramientas + card de ruta
          Align(
            alignment: Alignment.bottomCenter,

            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.md),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: MapControls(
                        icons: routeToolIcons,
                        onPressed: (index) {},
                      ),
                    ),

                    const SizedBox(height: AppGap.group),

                    RouteCard(
                      title: 'Mejor ruta',

                      metrics: const [
                        TripMetric(value: '67', unit: '%', label: 'Match'),
                        TripMetric(
                          value: '2.7',
                          unit: 'km',
                          label: 'Distancia',
                        ),
                        TripMetric(value: '23', unit: 'min', label: 'Duración'),
                      ],

                      // navegación a ruta comenzada
                      onStart: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TripView(),
                          ),
                        );
                      },

                      onClose: () => Navigator.pop(context),
                      onSave: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
