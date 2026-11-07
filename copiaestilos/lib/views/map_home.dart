import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'map_background.dart';
import 'map_controls.dart';
import 'map_header.dart';
import 'search.dart';

// pantalla "Inicio Mapa"
class MapHomeView extends StatelessWidget {
  const MapHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Stack(
      children: [
        // mapa
        const Positioned.fill(child: MapBackground()),

        // buscador + chips
        Align(
          alignment: Alignment.topCenter,

          child: MapHeader(
            // navegación a buscador abierto
            onSearch: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchView()),
              );
            },
            onPlan: () {},
          ),
        ),

        // controles del mapa + panel de rutas
        Align(
          alignment: Alignment.bottomCenter,

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              // capas y ubicación
              Align(
                alignment: Alignment.centerRight,

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.sm,
                    vertical: AppPadding.md,
                  ),

                  child: MapControls(
                    icons: const [Icons.layers_outlined, Icons.my_location],
                    onPressed: (index) {},
                  ),
                ),
              ),

              // panel colapsado "20 rutas"
              Container(
                padding: const EdgeInsets.only(
                  top: AppPadding.sm,
                  bottom: AppGap.nav,
                ),

                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.md),
                  ),
                ),

                child: Column(
                  children: [
                    // manija
                    Container(
                      width: 32,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.neutral300,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),

                    const SizedBox(height: AppGap.tight),

                    Text(
                      '20 rutas',
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
