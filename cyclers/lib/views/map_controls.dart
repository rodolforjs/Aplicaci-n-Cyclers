import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../theme/theme.dart';

// botones flotantes del mapa en una píldora vertical (capas, ubicación, etc.)
class MapControls extends StatelessWidget {
  const MapControls({super.key, required this.icons, this.onPressed});

  final List<IconData> icons;

  // recibe la posición del botón presionado
  final ValueChanged<int>? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PointerInterceptor(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
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
      ),
    );
  }
}
