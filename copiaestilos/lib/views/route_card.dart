import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'trip_metrics.dart';

// card de ruta sugerida: métricas + iniciar, cerrar y guardar
class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.title,
    required this.metrics,
    this.onStart,
    this.onClose,
    this.onSave,
  });

  final String title;
  final List<TripMetric> metrics;
  final VoidCallback? onStart;
  final VoidCallback? onClose;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // botón circular con borde
    final outlined = IconButton.styleFrom(
      backgroundColor: AppColors.neutral0,
      foregroundColor: colors.onSurface,
      side: BorderSide(color: colors.outlineVariant),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.elevation2,
      ),

      child: Padding(
        padding: const EdgeInsets.all(AppPadding.xs),

        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.md,
            vertical: AppPadding.sm,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              TripMetrics(title: title, metrics: metrics),

              const SizedBox(height: AppGap.component),

              Row(
                children: [
                  // iniciar
                  Expanded(
                    child: FilledButton(
                      onPressed: onStart,
                      child: const Text('Iniciar'),
                    ),
                  ),

                  const SizedBox(width: AppGap.related),

                  // cerrar
                  IconButton.outlined(
                    style: outlined,
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),

                  const SizedBox(width: AppGap.related),

                  // guardar
                  IconButton.outlined(
                    style: outlined,
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: onSave,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
