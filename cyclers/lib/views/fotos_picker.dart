import 'package:flutter/material.dart';
import '../services/fotos_service.dart';
import '../theme/app_icons.dart';
import '../theme/theme.dart';

// sección "Fotos": sin fotos muestra la caja punteada "¡Añade fotos!";
// con fotos muestra las miniaturas en fila y un botón para sumar más.
// Lo usan el formulario de lugar y el de fin de recorrido.
class FotosPicker extends StatelessWidget {
  const FotosPicker({
    super.key,
    required this.nuevas,
    required this.onAgregar,
    required this.onQuitar,
    this.guardadas = const [],
    this.habilitado = true,
  });

  // elegidas en este formulario, aún sin subir
  final List<FotoNueva> nuevas;
  // URLs de fotos que ya estaban subidas (al editar)
  final List<String> guardadas;
  final VoidCallback onAgregar;
  // índice dentro de "nuevas"
  final ValueChanged<int> onQuitar;
  final bool habilitado;

  static const double _alto = 96;
  // las miniaturas se decodifican chicas (96 px x3 de densidad) y no a
  // 1600 px: menos memoria y no se traba al agregar varias fotos
  static const int _decodificar = 288;

  @override
  Widget build(BuildContext context) {
    final total = guardadas.length + nuevas.length;
    if (total == 0) return _CajaVacia(onTap: habilitado ? onAgregar : null);

    return SizedBox(
      height: _alto,

      child: ListView(
        scrollDirection: Axis.horizontal,

        children: [
          for (final url in guardadas)
            _Miniatura(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: _decodificar,
                // en web, si el navegador no deja leerla, la muestra como imagen normal
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              ),
            ),

          for (var i = 0; i < nuevas.length; i++)
            _Miniatura(
              onQuitar: habilitado ? () => onQuitar(i) : null,
              child: Image.memory(
                nuevas[i].bytes,
                fit: BoxFit.cover,
                cacheWidth: _decodificar,
                // sin parpadeo al quitar una foto de la fila
                gaplessPlayback: true,
              ),
            ),

          if (total < FotosService.maximo)
            _BotonAgregar(onTap: habilitado ? onAgregar : null),
        ],
      ),
    );
  }
}

// caja punteada del Figma
class _CajaVacia extends StatelessWidget {
  const _CajaVacia({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return CustomPaint(
      painter: _BordePunteado(colors.onSurface),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),

          child: SizedBox(
            width: double.infinity,
            height: 120,

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Icon(AppIcons.fotos, color: colors.primary),
                const SizedBox(height: AppGap.related),
                Text('¡Añade fotos!', style: text.bodyLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.child, this.onQuitar});

  final Widget child;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: AppGap.related),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),

        child: SizedBox.square(
          dimension: FotosPicker._alto,

          child: Stack(
            fit: StackFit.expand,

            children: [
              child,

              if (onQuitar != null)
                Positioned(
                  top: AppSpacing.space100,
                  right: AppSpacing.space100,

                  child: IconButton.filled(
                    tooltip: 'Quitar foto',
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surfaceContainerLowest,
                      foregroundColor: colors.onSurface,
                    ),
                    icon: const Icon(Icons.close),
                    onPressed: onQuitar,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonAgregar extends StatelessWidget {
  const _BotonAgregar({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CustomPaint(
      painter: _BordePunteado(colors.onSurface),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),

          child: SizedBox.square(
            dimension: FotosPicker._alto,
            child: Icon(AppIcons.agregarFoto, color: colors.primary),
          ),
        ),
      ),
    );
  }
}

// Flutter no trae borde punteado: se dibuja el contorno a tramos
class _BordePunteado extends CustomPainter {
  _BordePunteado(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final contorno = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.lg),
        ),
      );

    for (final tramo in contorno.computeMetrics()) {
      var distancia = 0.0;
      while (distancia < tramo.length) {
        canvas.drawPath(tramo.extractPath(distancia, distancia + 3), pincel);
        distancia += 6;
      }
    }
  }

  @override
  bool shouldRepaint(_BordePunteado oldDelegate) => oldDelegate.color != color;
}
