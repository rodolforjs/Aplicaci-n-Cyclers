import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../theme/theme.dart';
import 'trip_metrics.dart';

// card de ruta sugerida: métricas + iniciar, cerrar y guardar
class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.title,
    required this.metrics,
    this.startLabel = 'Iniciar',
    this.onStart,
    this.onClose,
    this.onSave,
  });

  final String title;
  final List<TripMetric> metrics;
  final String startLabel;
  final VoidCallback? onStart;
  final VoidCallback? onClose;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // botón circular con borde
    final outlined = IconButton.styleFrom(
      backgroundColor: colors.surfaceContainerLowest,
      foregroundColor: colors.onSurface,
      side: BorderSide(color: colors.outlineVariant),
    );

    // en web, los toques sobre la card no deben llegar al mapa de abajo
    return PointerInterceptor(
      child: DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
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
                      child: Text(startLabel),
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
    ),
    );
  }
}
