import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../theme/app_icons.dart';
import '../theme/theme.dart';

// dificultades: se eligen al guardar y sirven para filtrar
const List<String> kDificultades = ['Fácil', 'Media', 'Difícil'];

enum OrdenRutas { recientes, antiguas }

// qué mostrar: todo, solo lugares o solo rutas
enum TipoGuardado { todos, lugares, rutas }

// filtros activos sobre la lista de guardados y los marcadores del mapa
class FiltrosRutas {
  const FiltrosRutas({
    this.tipo = TipoGuardado.todos,
    this.dificultad,
    this.orden = OrdenRutas.recientes,
    this.bici,
  });

  final TipoGuardado tipo;
  // null = todas
  final String? dificultad;
  final OrdenRutas orden;
  // modo (tipo de bici); null = todas. Se elige con el chip de la bici.
  final String? bici;

  // cuántos filtros del panel "Filtros" están cambiados.
  // La bici no cuenta: ya se ve en su propio chip.
  int get cantidad =>
      (tipo != TipoGuardado.todos ? 1 : 0) +
      (dificultad != null ? 1 : 0) +
      (orden != OrdenRutas.recientes ? 1 : 0);

  bool get activo => cantidad > 0 || bici != null;

  FiltrosRutas conBici(String? nueva) =>
      FiltrosRutas(tipo: tipo, dificultad: dificultad, orden: orden, bici: nueva);
}

// busca por título o descripción (como el buscador de noticias del profe),
// filtra por tipo, dificultad y bici, y ordena por fecha
List<QueryDocumentSnapshot<Map<String, dynamic>>> filtrarRutas(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
  String busqueda = '',
  FiltrosRutas filtros = const FiltrosRutas(),
}) {
  final resultado = docs.where((doc) {
    final datos = doc.data();
    // los guardados antes de separar lugar y ruta no tienen tipo: son lugares
    final esRuta = datos['tipo'] == 'ruta';

    if (filtros.tipo == TipoGuardado.lugares && esRuta) return false;
    if (filtros.tipo == TipoGuardado.rutas && !esRuta) return false;

    if (filtros.dificultad != null &&
        datos['dificultad'] != filtros.dificultad) {
      return false;
    }

    // la bici solo filtra rutas: un lugar sirve para cualquier bici
    if (filtros.bici != null && esRuta && datos['bici'] != filtros.bici) {
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

  // uno recién guardado todavía no tiene fecha: cuenta como el más nuevo
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
    // sin esto la hoja se corta a ~56 % del alto y el contenido se desborda
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) =>
        PointerInterceptor(child: _FiltrosSheet(actuales: actuales)),
  );
}

// abre la elección de modo (tipo de bici) del chip de la bici.
// Devuelve los filtros con la bici cambiada, o null si se cierra.
Future<FiltrosRutas?> mostrarModo(
  BuildContext context,
  FiltrosRutas actuales,
) {
  return showModalBottomSheet<FiltrosRutas>(
    context: context,
    // sin esto la hoja se corta a ~56 % del alto y el contenido se desborda
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) =>
        PointerInterceptor(child: _ModoSheet(actuales: actuales)),
  );
}

class _FiltrosSheet extends StatefulWidget {
  const _FiltrosSheet({required this.actuales});

  final FiltrosRutas actuales;

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late TipoGuardado _tipo = widget.actuales.tipo;
  late String? _dificultad = widget.actuales.dificultad;
  late OrdenRutas _orden = widget.actuales.orden;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      // en pantallas bajas se puede hacer scroll en vez de desbordarse
      child: SingleChildScrollView(
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

            // qué mostrar (segmented button, como en componentes del profe)
            Text('Mostrar', style: text.titleMedium),

            const SizedBox(height: AppGap.related),

            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TipoGuardado>(
                segments: const [
                  ButtonSegment(
                    value: TipoGuardado.todos,
                    label: Text('Todos'),
                    icon: Icon(AppIcons.todos),
                  ),
                  ButtonSegment(
                    value: TipoGuardado.lugares,
                    label: Text('Lugares'),
                    icon: Icon(AppIcons.lugar),
                  ),
                  ButtonSegment(
                    value: TipoGuardado.rutas,
                    label: Text('Rutas'),
                    icon: Icon(AppIcons.ruta),
                  ),
                ],
                selected: {_tipo},
                // el ícono del segmento ya dice cuál está elegido
                showSelectedIcon: false,
                onSelectionChanged: (seleccion) =>
                    setState(() => _tipo = seleccion.first),
              ),
            ),

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
                    avatar: Icon(kIconosDificultad[d]),
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
                  avatar: const Icon(AppIcons.recientes),
                  label: const Text('Más recientes'),
                  selected: _orden == OrdenRutas.recientes,
                  onSelected: (_) =>
                      setState(() => _orden = OrdenRutas.recientes),
                ),
                ChoiceChip(
                  avatar: const Icon(AppIcons.antiguas),
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
                    // limpiar no toca la bici: esa tiene su propio chip
                    onPressed: () => Navigator.pop(
                      context,
                      FiltrosRutas(bici: widget.actuales.bici),
                    ),
                    child: const Text('Limpiar'),
                  ),
                ),

                const SizedBox(width: AppGap.related),

                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      FiltrosRutas(
                        tipo: _tipo,
                        dificultad: _dificultad,
                        orden: _orden,
                        bici: widget.actuales.bici,
                      ),
                    ),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// elegir modo: al tocar una opción se aplica y se cierra
class _ModoSheet extends StatelessWidget {
  const _ModoSheet({required this.actuales});

  final FiltrosRutas actuales;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget opcion(String? bici, IconData icono, String nombre) {
      final elegida = actuales.bici == bici;
      return ListTile(
        leading: Icon(icono, color: colors.tertiary),
        title: Text(nombre),
        trailing: elegida ? Icon(Icons.check, color: colors.primary) : null,
        selected: elegida,
        onTap: () => Navigator.pop(context, actuales.conBici(bici)),
      );
    }

    return SafeArea(
      // en pantallas bajas se puede hacer scroll en vez de desbordarse
      child: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppPadding.md,
          AppPadding.sm,
          AppPadding.md,
          AppPadding.md,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text('Modo', style: text.titleLarge),

            const SizedBox(height: AppGap.tight),

            Text(
              'Muestra las rutas hechas para esa bici. '
              'Los lugares se ven siempre.',
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),

            const SizedBox(height: AppGap.related),

            opcion(null, AppIcons.bici, 'Todas las bicis'),
            for (final bici in kBicis.entries)
              opcion(bici.key, bici.value, bici.key),
          ],
        ),
      ),
      ),
    );
  }
}
