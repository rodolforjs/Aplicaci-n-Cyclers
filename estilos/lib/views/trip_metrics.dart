import 'package:flutter/material.dart';
import '../theme/theme.dart';

// bloque de datos del viaje: título + fila de métricas (Registro, Mejor ruta)
class TripMetrics extends StatelessWidget {
  const TripMetrics({super.key, required this.title, required this.metrics});

  final String title;
  final List<TripMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(title, style: text.labelMedium),

        const SizedBox(height: AppGap.related),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: metrics),
      ],
    );
  }
}

// una métrica: número en DM Mono + unidad + etiqueta
class TripMetric extends StatelessWidget {
  const TripMetric({
    super.key,
    required this.value,
    required this.unit,
    required this.label,
  });

  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: value, style: AppTypography.data2),

              TextSpan(text: ' $unit', style: text.bodyLarge),
            ],
          ),
        ),

        const SizedBox(height: AppGap.tight),

        Text(label, style: text.labelSmall),
      ],
    );
  }
}
