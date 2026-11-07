import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'map_background.dart';
import 'map_header.dart';
import 'place_card.dart';
import 'pre_trip.dart';

// pantalla "Lugar seleccionado"
class PlaceView extends StatelessWidget {
  const PlaceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // mapa
          const Positioned.fill(child: MapBackground()),

          // buscador + chips
          const Align(alignment: Alignment.topCenter, child: MapHeader()),

          // card del lugar
          Align(
            alignment: Alignment.bottomCenter,

            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.md),

                child: PlaceCard(
                  title: 'Cerro Santa Lucía',
                  category: 'Sitio histórico, Santiago, Chile',
                  note: 'Recomendado por la comunidad',
                  photoLeft: 'assets/images/cerro_1.png',
                  photoRight: 'assets/images/cerro_2.png',

                  // cerrar vuelve al mapa
                  onClose: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },

                  // navegación a precomienzo del viaje
                  onStart: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PreTripView(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
