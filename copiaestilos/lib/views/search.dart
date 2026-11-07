import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'place.dart';
import 'place_tile.dart';
import 'search_field.dart';

// pantalla "Buscador Abierto"
class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppMargin.md,
            AppMargin.lg,
            AppMargin.md,
            AppMargin.md,
          ),

          children: [
            // campo de búsqueda
            SearchField(
              hint: 'Busca lugares o rutas',
              autofocus: true,
              onBack: () => Navigator.pop(context),
            ),

            const SizedBox(height: AppGap.component),

            // atajos
            PlaceTile(
              icon: Icons.home,
              iconColor: colors.tertiary,
              iconBackground: AppColors.accent100,
              title: 'Comienza desde casa',
              subtitle: 'Morande 626',
              onTap: () {},
            ),

            const SizedBox(height: AppGap.related),

            PlaceTile(
              icon: Icons.near_me,
              iconColor: colors.primary,
              iconBackground: colors.primaryContainer,
              title: 'Viajes desde tu ubicación actual',
              onTap: () {},
            ),

            const SizedBox(height: AppGap.component),

            // recientes
            Text(
              'Búsquedas recientes',
              style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: AppGap.related),

            PlaceTile(
              icon: Icons.landscape,
              iconColor: colors.tertiary,
              iconBackground: AppColors.accent100,
              title: 'Cerro Santa Lucía',
              subtitle: 'Sitio histórico, Chile',

              // navegación a lugar seleccionado
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlaceView()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
