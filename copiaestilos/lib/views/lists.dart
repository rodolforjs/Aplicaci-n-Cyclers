import 'package:flutter/material.dart';

import '../theme/theme.dart';

// Placeholder: el main del profe importa ListsView, pero este archivo no
// vino con él. Reemplazar cuando el profe pase la vista real.
class ListsView extends StatelessWidget {
  const ListsView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Listas')),
      body: Padding(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Text('Pendiente', style: text.headlineMedium),
      ),
    );
  }
}
