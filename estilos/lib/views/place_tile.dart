import 'package:flutter/material.dart';
import '../theme/theme.dart';

// fila de lugar: ícono en cuadrado de color + título + subtítulo (un ListTile)
class PlaceTile extends StatelessWidget {
  const PlaceTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  // acción opcional a la derecha (ej. menú editar/eliminar)
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,

      contentPadding: const EdgeInsets.symmetric(horizontal: AppPadding.sm),
      minTileHeight: 46,
      minVerticalPadding: AppPadding.xs,
      horizontalTitleGap: AppGap.related,

      leading: Container(
        width: 38,
        height: 38,

        decoration: BoxDecoration(
          color: iconBackground,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),

        child: Icon(icon, size: 20, color: iconColor),
      ),

      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
    );
  }
}
