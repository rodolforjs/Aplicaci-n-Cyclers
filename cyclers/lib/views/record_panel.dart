import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'trip_metrics.dart';

// panel inferior del viaje: registro (métricas) + tiempo y botones.
// Andando: "Pausar". Pausado: "Seguir" y "Terminar" (Figma: Ruta pausada).
class RecordPanel extends StatelessWidget {
  const RecordPanel({
    super.key,
    required this.metrics,
    required this.time,
    this.paused = false,
    this.onPause,
    this.onResume,
    this.onFinish,
  });

  final List<TripMetric> metrics;
  final String time;
  final bool paused;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [
        // registro
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.lg,
            vertical: AppPadding.sm,
          ),

          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
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
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),

              const SizedBox(height: AppGap.related),

              TripMetrics(title: 'Registro', metrics: metrics),
            ],
          ),
        ),

        // tiempo + botones
        Container(
          color: colors.surface,

          child: SafeArea(
            top: false,

            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.lg,
                vertical: AppSpacing.space300,
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(time, style: AppTypography.data2),

                      const SizedBox(height: AppGap.tight),

                      Text('Tiempo', style: text.labelSmall),
                    ],
                  ),

                  if (paused)
                    Row(
                      children: [
                        FilledButton.tonal(
                          onPressed: onResume,
                          child: const Text('Seguir'),
                        ),

                        const SizedBox(width: AppGap.related),

                        FilledButton(
                          onPressed: onFinish,
                          child: const Text('Terminar'),
                        ),
                      ],
                    )
                  else
                    FilledButton(
                      onPressed: onPause,
                      child: const Text('Pausar'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
