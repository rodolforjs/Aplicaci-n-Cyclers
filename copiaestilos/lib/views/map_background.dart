import 'package:flutter/material.dart';

// fondo de mapa (imagen exportada de Figma), se usa dentro de un Stack
class MapBackground extends StatelessWidget {
  const MapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox.expand(
      child: Image.asset(
        'assets/images/map.png',
        fit: BoxFit.cover,
        alignment: const Alignment(-0.55, 0),

        // si la imagen aún no está en assets, se ve un fondo liso
        errorBuilder: (context, error, stackTrace) {
          return ColoredBox(color: colors.surfaceContainer);
        },
      ),
    );
  }
}
