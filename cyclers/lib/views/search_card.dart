import 'package:flutter/material.dart';
import '../theme/theme.dart';

// buscador del mapa: "Busca un destino" + "Planificar"
class SearchCard extends StatelessWidget {
  const SearchCard({super.key, this.onSearch, this.onPlan});

  final VoidCallback? onSearch;
  final VoidCallback? onPlan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.elevation1,
      ),

      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,

        child: Row(
          children: [
            // buscar
            Expanded(
              child: InkWell(
                onTap: onSearch,

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.md,
                    vertical: AppSpacing.space300,
                  ),

                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),

                      const SizedBox(width: AppGap.related),

                      Text(
                        'Busca un destino',
                        style: text.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // divisor
            Container(width: 1, height: 20, color: colors.outlineVariant),

            // planificar
            InkWell(
              onTap: onPlan,

              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.md,
                  vertical: AppSpacing.space300,
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),

                    const SizedBox(width: AppGap.related),

                    Text(
                      'Planificar',
                      style: text.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
