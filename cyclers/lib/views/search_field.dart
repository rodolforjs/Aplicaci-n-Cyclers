import 'package:flutter/material.dart';
import '../theme/theme.dart';

// campo de búsqueda abierto: flecha atrás + texto, con borde brand
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hint,
    this.autofocus = false,
    this.controller,
    this.onChanged,
    this.onBack,
  });

  final String hint;
  final bool autofocus;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: colors.primary),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.elevation1,
      ),

      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        style: text.bodyLarge,

        decoration: InputDecoration(
          hintText: hint,
          hintStyle: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),

          filled: true,
          fillColor: colors.surfaceContainerLowest,

          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space300,
          ),

          prefixIcon: IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            color: colors.onSurfaceVariant,
            onPressed: onBack,
          ),

          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
      ),
    );
  }
}
