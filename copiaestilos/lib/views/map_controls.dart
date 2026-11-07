import 'package:flutter/material.dart';
import '../theme/theme.dart';

// íconos de las herramientas de ruta (relieve, alertas, tráfico, favoritos)
const List<IconData> routeToolIcons = [
  Icons.terrain,
  Icons.report_problem_outlined,
  Icons.directions_car_outlined,
  Icons.favorite_border,
];

// botones flotantes del mapa en una píldora vertical (capas, ubicación, etc.)
class MapControls extends StatelessWidget {
  const MapControls({super.key, required this.icons, this.onPressed});

  final List<IconData> icons;

  // recibe la posición del botón presionado
  final ValueChanged<int>? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: AppShadows.elevation3,
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          for (var i = 0; i < icons.length; i++) ...[
            // divisor entre botones
            if (i > 0)
              SizedBox(
                width: 32,
                child: Divider(height: 1, color: colors.outlineVariant),
              ),

            IconButton(
              icon: Icon(icons[i]),
              color: colors.onSurface,
              onPressed: onPressed == null ? null : () => onPressed!(i),
            ),
          ],
        ],
      ),
    );
  }
}
