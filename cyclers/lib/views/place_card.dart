import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../theme/app_icons.dart';
import '../theme/theme.dart';

// card de resultado: dos fotos, guardar/cerrar, datos del lugar y botón
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.title,
    required this.category,
    required this.note,
    this.categoryIcon = AppIcons.lugarSinGuardar,
    this.photoLeft,
    this.photoRight,
    this.fotoUrl,
    this.fotoAutor,
    this.onSaveRoute,
    this.onClose,
    this.onStart,
  });

  final String title;
  final String category;
  final String note;
  final IconData categoryIcon;
  final String? photoLeft;
  final String? photoRight;

  // foto de Google ya aprobada y quien la tomó
  final String? fotoUrl;
  final String? fotoAutor;
  final VoidCallback? onSaveRoute;
  final VoidCallback? onClose;
  final VoidCallback? onStart;

  static const double _altoFotos = 89;
  static const double _altoFotoGrande = 132;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tieneFotos =
        photoLeft != null || photoRight != null || fotoUrl != null;

    // botón circular blanco sobre la foto
    final overlayButton = IconButton.styleFrom(
      backgroundColor: colors.surfaceContainerLowest,
      foregroundColor: colors.onSurface,
      fixedSize: const Size(32, 32),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.padded,
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

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              // fotos (si no hay, la card queda compacta)
              if (tieneFotos)
                SizedBox(
                  height: fotoUrl != null ? _altoFotoGrande : _altoFotos,

                  child: Stack(
                    children: [
                      fotoUrl != null
                          ? Positioned.fill(
                              child: _FotoRed(url: fotoUrl!, autor: fotoAutor),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _Photo(
                                    path: photoLeft,
                                    radius: const BorderRadius.only(
                                      topLeft: Radius.circular(AppRadius.xl),
                                      topRight: Radius.circular(AppRadius.sm),
                                      bottomLeft: Radius.circular(AppRadius.sm),
                                      bottomRight: Radius.circular(
                                        AppRadius.sm,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: AppGap.tight),

                                Expanded(
                                  child: _Photo(
                                    path: photoRight,
                                    radius: const BorderRadius.only(
                                      topLeft: Radius.circular(AppRadius.sm),
                                      topRight: Radius.circular(AppRadius.xl),
                                      bottomLeft: Radius.circular(AppRadius.sm),
                                      bottomRight: Radius.circular(
                                        AppRadius.sm,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                      // cerrar
                      Positioned(
                        top: AppPadding.sm,
                        right: AppPadding.sm,

                        child: IconButton(
                          style: overlayButton,
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: onClose,
                        ),
                      ),
                    ],
                  ),
                ),

              // datos
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.md,
                  vertical: AppPadding.sm,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // categoría
                    Row(
                      children: [
                        Icon(categoryIcon, size: 18, color: colors.tertiary),

                        const SizedBox(width: AppGap.tight),

                        Expanded(
                          child: Text(
                            category,
                            style: text.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),

                        // sin fotos, cerrar va junto a la categoría
                        if (!tieneFotos)
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: onClose,
                          ),
                      ],
                    ),

                    const SizedBox(height: AppGap.tight),

                    // nombre
                    Text(title, style: text.titleLarge),

                    if (note.isNotEmpty)
                      Text(
                        note,
                        style: text.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),

                    const SizedBox(height: AppGap.component),

                    // guardar lugar (si se puede) y comenzar
                    Row(
                      children: [
                        if (onSaveRoute != null) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onSaveRoute,
                              child: const Text('Guardar lugar'),
                            ),
                          ),

                          const SizedBox(width: AppGap.related),
                        ],

                        Expanded(
                          child: FilledButton(
                            onPressed: onStart,
                            child: const Text('Comenzar viaje'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// foto con esquinas distintas; si falta el archivo, muestra un fondo liso
class _Photo extends StatelessWidget {
  const _Photo({required this.path, required this.radius});

  final String? path;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final archivo = path;

    // sin foto: fondo liso
    if (archivo == null) {
      return ClipRRect(
        borderRadius: radius,
        child: ColoredBox(color: colors.primaryContainer),
      );
    }

    return ClipRRect(
      borderRadius: radius,

      child: Image.asset(
        archivo,
        fit: BoxFit.cover,
        height: double.infinity,

        errorBuilder: (context, error, stackTrace) {
          return ColoredBox(color: colors.primaryContainer);
        },
      ),
    );
  }
}

// foto de Google a todo el ancho, con el crédito de quien la tomó
class _FotoRed extends StatelessWidget {
  const _FotoRed({required this.url, this.autor});

  final String url;
  final String? autor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fondo = ColoredBox(color: colors.primaryContainer);
    final credito = autor;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppRadius.xl),
        topRight: Radius.circular(AppRadius.xl),
        bottomLeft: Radius.circular(AppRadius.sm),
        bottomRight: Radius.circular(AppRadius.sm),
      ),

      child: Stack(
        fit: StackFit.expand,

        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            // en web, si el navegador no deja leerla, la muestra como imagen normal
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            loadingBuilder: (context, child, progreso) {
              return progreso == null ? child : fondo;
            },
            errorBuilder: (context, error, stackTrace) => fondo,
          ),

          if (credito != null && credito.isNotEmpty)
            Positioned(
              left: AppPadding.sm,
              bottom: AppPadding.xs,

              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.inverseSurface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.xs,
                    vertical: AppSpacing.space050,
                  ),
                  child: Text(
                    'Foto: $credito',
                    style: text.labelSmall?.copyWith(
                      color: colors.onInverseSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
