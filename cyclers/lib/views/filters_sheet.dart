import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../theme/theme.dart';

// dificultades: se eligen al guardar una ruta y sirven para filtrar
const List<String> kDificultades = ['Fácil', 'Media', 'Difícil'];

enum OrdenRutas { recientes, antiguas }

// filtros activos sobre la lista de rutas y los marcadores del mapa
class FiltrosRutas {
  const FiltrosRutas({this.dificultad, this.orden = OrdenRutas.recientes});

  // null = todas
  final String? dificultad;
  final OrdenRutas orden;

  // cuántos filtros están distintos del valor por defecto
  int get cantidad =>
      (dificultad != null ? 1 : 0) + (orden != OrdenRutas.recientes ? 1 : 0);

  bool get activo => cantidad > 0;
}

// busca por título o descripción (como el buscador de noticias del profe),
// filtra por dificultad y ordena por fecha
List<QueryDocumentSnapshot<Map<String, dynamic>>> filtrarRutas(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
  String busqueda = '',
  FiltrosRutas filtros = const FiltrosRutas(),
}) {
  final resultado = docs.where((doc) {
    final datos = doc.data();
    if (filtros.dificultad != null &&
        datos['dificultad'] != filtros.dificultad) {
      return false;
    }
    if (busqueda.isEmpty) return true;
    return (datos['titulo'] ?? '').toString().toLowerCase().contains(
          busqueda,
        ) ||
        (datos['descripcion'] ?? '').toString().toLowerCase().contains(
          busqueda,
        );
  }).toList();

  // una ruta recién guardada todavía no tiene fecha: cuenta como la más nueva
  final ahora = DateTime.now().millisecondsSinceEpoch;
  int fecha(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final t = doc.data()['creadoEn'];
    return t is Timestamp ? t.millisecondsSinceEpoch : ahora;
  }

  resultado.sort(
    (a, b) => filtros.orden == OrdenRutas.recientes
        ? fecha(b).compareTo(fecha(a))
        : fecha(a).compareTo(fecha(b)),
  );
  return resultado;
}

// abre el panel de filtros; devuelve null si se cierra sin aplicar
Future<FiltrosRutas?> mostrarFiltros(
  BuildContext context,
  FiltrosRutas actuales,
) {
  return showModalBottomSheet<FiltrosRutas>(
    context: context,
    showDragHandle: true,
    builder: (context) =>
        PointerInterceptor(child: _FiltrosSheet(actuales: actuales)),
  );
}

class _FiltrosSheet extends StatefulWidget {
  const _FiltrosSheet({required this.actuales});

  final FiltrosRutas actuales;

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late String? _dificultad = widget.actuales.dificultad;
  late OrdenRutas _orden = widget.actuales.orden;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppPadding.md,
          AppPadding.sm,
          AppPadding.md,
          AppPadding.lg,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text('Filtros', style: text.titleLarge),

            const SizedBox(height: AppGap.component),

            // dificultad
            Text('Dificultad', style: text.titleMedium),

            const SizedBox(height: AppGap.related),

            Wrap(
              spacing: AppGap.related,
              runSpacing: AppGap.related,
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _dificultad == null,
                  onSelected: (_) => setState(() => _dificultad = null),
                ),
                for (final d in kDificultades)
                  ChoiceChip(
                    label: Text(d),
                    selected: _dificultad == d,
                    onSelected: (_) => setState(() => _dificultad = d),
                  ),
              ],
            ),

            const SizedBox(height: AppGap.component),

            // orden
            Text('Orden', style: text.titleMedium),

            const SizedBox(height: AppGap.related),

            Wrap(
              spacing: AppGap.related,
              runSpacing: AppGap.related,
              children: [
                ChoiceChip(
                  label: const Text('Más recientes'),
                  selected: _orden == OrdenRutas.recientes,
                  onSelected: (_) =>
                      setState(() => _orden = OrdenRutas.recientes),
                ),
                ChoiceChip(
                  label: const Text('Más antiguas'),
                  selected: _orden == OrdenRutas.antiguas,
                  onSelected: (_) =>
                      setState(() => _orden = OrdenRutas.antiguas),
                ),
              ],
            ),

            const SizedBox(height: AppGap.section),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(context, const FiltrosRutas()),
                    child: const Text('Limpiar'),
                  ),
                ),

                const SizedBox(width: AppGap.related),

                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      FiltrosRutas(dificultad: _dificultad, orden: _orden),
                    ),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
