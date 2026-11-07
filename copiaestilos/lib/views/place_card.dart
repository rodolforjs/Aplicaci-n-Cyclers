import 'package:flutter/material.dart';
import '../theme/theme.dart';

// card de resultado: dos fotos, guardar/cerrar, datos del lugar y botón
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.title,
    required this.category,
    required this.note,
    required this.photoLeft,
    required this.photoRight,
    this.onSave,
    this.onClose,
    this.onStart,
  });

  final String title;
  final String category;
  final String note;
  final String photoLeft;
  final String photoRight;
  final VoidCallback? onSave;
  final VoidCallback? onClose;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    // botón circular blanco sobre la foto
    final overlayButton = IconButton.styleFrom(
      backgroundColor: AppColors.neutral0,
      foregroundColor: colors.onSurface,
      fixedSize: const Size(32, 32),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.padded,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.elevation2,
      ),

      child: Padding(
        padding: const EdgeInsets.all(AppPadding.xs),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            // fotos
            SizedBox(
              height: 89,

              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Photo(
                          path: photoLeft,
                          radius: const BorderRadius.only(
                            topLeft: Radius.circular(AppRadius.xl),
                            topRight: Radius.circular(AppRadius.sm),
                            bottomLeft: Radius.circular(AppRadius.sm),
                            bottomRight: Radius.circular(AppRadius.sm),
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
                            bottomRight: Radius.circular(AppRadius.sm),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // guardar y cerrar
                  Positioned(
                    top: AppPadding.sm,
                    right: AppPadding.sm,

                    child: Row(
                      children: [
                        IconButton(
                          style: overlayButton,
                          icon: const Icon(Icons.bookmark_border, size: 20),
                          onPressed: onSave,
                        ),

                        const SizedBox(width: AppGap.related),

                        IconButton(
                          style: overlayButton,
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: onClose,
                        ),
                      ],
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
                      Icon(Icons.landscape, size: 18, color: colors.tertiary),

                      const SizedBox(width: AppGap.tight),

                      Text(
                        category,
                        style: text.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppGap.tight),

                  // nombre
                  Text(title, style: text.titleLarge),

                  Text(
                    note,
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: AppGap.component),

                  // comenzar
                  SizedBox(
                    width: double.infinity,

                    child: FilledButton(
                      onPressed: onStart,
                      child: const Text('Comenzar viaje'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// foto con esquinas distintas; si falta el archivo, muestra un fondo liso
class _Photo extends StatelessWidget {
  const _Photo({required this.path, required this.radius});

  final String path;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: radius,

      child: Image.asset(
        path,
        fit: BoxFit.cover,
        height: double.infinity,

        errorBuilder: (context, error, stackTrace) {
          return ColoredBox(color: colors.primaryContainer);
        },
      ),
    );
  }
}
