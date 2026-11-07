import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'map_chip.dart';
import 'search_card.dart';

// parte superior del mapa: buscador + chips (tipo de bici y filtros)
class MapHeader extends StatelessWidget {
  const MapHeader({super.key, this.onSearch, this.onPlan});

  final VoidCallback? onSearch;
  final VoidCallback? onPlan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppMargin.md,
          AppMargin.lg,
          AppMargin.md,
          0,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,

          children: [
            SearchCard(onSearch: onSearch, onPlan: onPlan),

            const SizedBox(height: AppGap.related),

            Row(
              children: [
                MapChip(
                  icon: Icons.directions_bike,
                  iconColor: colors.tertiary,
                  showArrow: true,
                  onTap: () {},
                ),

                const SizedBox(width: AppGap.related),

                MapChip(
                  icon: Icons.filter_alt_outlined,
                  label: 'Filtros',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
