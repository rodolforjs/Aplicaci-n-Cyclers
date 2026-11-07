import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../theme/theme.dart';
import 'map_chip.dart';
import 'search_card.dart';

// parte superior del mapa: buscador + chips (tipo de bici y filtros)
class MapHeader extends StatelessWidget {
  const MapHeader({
    super.key,
    this.onSearch,
    this.onPlan,
    this.onFilters,
    this.filtrosActivos = 0,
    this.mostrarChips = true,
  });

  final VoidCallback? onSearch;
  final VoidCallback? onPlan;
  final VoidCallback? onFilters;

  // cantidad de filtros aplicados (0 = ninguno)
  final int filtrosActivos;

  // false en pantallas donde los chips no aplican (ej. lugar seleccionado)
  final bool mostrarChips;

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
            PointerInterceptor(
              child: SearchCard(onSearch: onSearch, onPlan: onPlan),
            ),

            if (mostrarChips) ...[
              const SizedBox(height: AppGap.related),

              PointerInterceptor(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                      iconColor: filtrosActivos > 0 ? colors.primary : null,
                      label: filtrosActivos > 0
                          ? 'Filtros ($filtrosActivos)'
                          : 'Filtros',
                      onTap: onFilters,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
