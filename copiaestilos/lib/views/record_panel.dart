import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'trip_metrics.dart';

// panel inferior del viaje: registro (métricas) + tiempo y botón pausar
class RecordPanel extends StatelessWidget {
  const RecordPanel({
    super.key,
    required this.metrics,
    required this.time,
    this.onPause,
  });

  final List<TripMetric> metrics;
  final String time;
  final VoidCallback? onPause;

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
            color: AppColors.neutral0,
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

              const SizedBox(height: AppGap.related),

              TripMetrics(title: 'Registro', metrics: metrics),
            ],
          ),
        ),

        // tiempo + pausar
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

                  FilledButton(onPressed: onPause, child: const Text('Pausar')),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
