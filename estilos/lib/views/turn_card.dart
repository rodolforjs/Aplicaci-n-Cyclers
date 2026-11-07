import 'package:flutter/material.dart';
import '../theme/theme.dart';

// instrucción de giro durante el viaje: "En 200 metros / Rosas"
class TurnCard extends StatelessWidget {
  const TurnCard({
    super.key,
    required this.distance,
    required this.street,
    this.onExpand,
  });

  final String distance;
  final String street;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.elevation2,
      ),

      child: Padding(
        padding: const EdgeInsets.all(AppPadding.md),

        child: Row(
          children: [
            Icon(Icons.turn_right, size: 24, color: colors.onPrimary),

            const SizedBox(width: AppGap.group),

            // distancia + calle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    distance,
                    style: text.titleLarge?.copyWith(color: colors.onPrimary),
                  ),

                  Text(
                    street,
                    style: text.bodyLarge?.copyWith(color: colors.onPrimary),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppGap.group),

            // expandir instrucciones
            IconButton.outlined(
              style: IconButton.styleFrom(
                backgroundColor: colors.surfaceContainerLowest,
                foregroundColor: colors.onSurface,
                side: BorderSide(color: colors.outlineVariant),
              ),
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: onExpand,
            ),
          ],
        ),
      ),
    );
  }
}
