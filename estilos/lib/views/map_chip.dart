import 'package:flutter/material.dart';
import '../theme/theme.dart';

// chip blanco que flota sobre el mapa (tipo de bici, filtros)
class MapChip extends StatelessWidget {
  const MapChip({
    super.key,
    required this.icon,
    this.label,
    this.iconColor,
    this.showArrow = false,
    this.onTap,
  });

  final IconData icon;
  final String? label;
  final Color? iconColor;
  final bool showArrow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.elevation1,
      ),

      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,

        child: InkWell(
          onTap: onTap,

          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: label == null ? AppSpacing.space300 : AppPadding.md,
              vertical: AppPadding.sm,
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: iconColor ?? colors.onSurfaceVariant,
                ),

                if (label != null) ...[
                  const SizedBox(width: AppGap.related),

                  Text(
                    label!,
                    style: text.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],

                if (showArrow) ...[
                  const SizedBox(width: AppGap.tight),

                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
