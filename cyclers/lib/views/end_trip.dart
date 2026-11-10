import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/fotos_service.dart';
import '../services/places_service.dart';
import '../services/routes_service.dart';
import '../theme/app_icons.dart';
import '../theme/theme.dart';
import 'fotos_picker.dart';

// pantalla "Detalles Guardar Ruta": se abre al terminar un viaje.
// Guarda un RECORRIDO en Firestore (colección "recorridos", tipo: 'recorrido')
// con sus fotos en Storage (carpeta recorridos/<id>/).
// "Omitir" guarda el recorrido igual, pero sin detalles ni fotos.
// Devuelve true si se guardó.
class EndTripView extends StatefulWidget {
  const EndTripView({
    super.key,
    required this.destino,
    required this.origen,
    required this.ruta,
    required this.duracion,
  });

  final Lugar destino;
  final LatLng origen;
  final RutaCalculada ruta;
  final Duration duracion;

  @override
  State<EndTripView> createState() => _EndTripViewState();
}

class _EndTripViewState extends State<EndTripView> {
  // 1 = mal, 2 = normal, 3 = bien (las caritas del Figma)
  static const List<(IconData, String)> _caritas = [
    (Icons.sentiment_dissatisfied_outlined, 'Mal'),
    (Icons.sentiment_neutral_outlined, 'Normal'),
    (Icons.sentiment_satisfied_outlined, 'Bien'),
  ];

  final _nombre = TextEditingController();
  final _comentario = TextEditingController();
  final List<FotoNueva> _fotos = [];
  String _bici = kBicis.keys.first;
  int? _calificacion;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _comentario.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _agregarFotos() async {
    try {
      final elegidas = await FotosService.elegir(
        cuantas: FotosService.maximo - _fotos.length,
      );
      if (!mounted || elegidas.isEmpty) return;
      setState(() => _fotos.addAll(elegidas));
    } catch (e) {
      debugPrint('Error eligiendo fotos: $e');
      if (mounted) _mensaje('No se pudieron abrir las fotos.');
    }
  }

  Future<void> _guardar({bool conDetalles = true}) async {
    if (_guardando) return;
    setState(() => _guardando = true);

    final doc = FirebaseFirestore.instance.collection('recorridos').doc();
    var subidas = <FotoSubida>[];

    try {
      if (conDetalles) {
        subidas = await FotosService.subir('recorridos', doc.id, _fotos);
      }

      final nombre = _nombre.text.trim();
      final destino = widget.destino;

      await doc.set({
        'tipo': 'recorrido',
        'usuario': FirebaseAuth.instance.currentUser?.uid,
        'titulo': conDetalles && nombre.isNotEmpty
            ? nombre
            : 'Viaje hacia ${destino.nombre}',
        if (conDetalles) ...{
          'comentario': _comentario.text.trim(),
          'bici': _bici,
          'calificacion': _calificacion,
        },
        'destino': {
          'nombre': destino.nombre,
          'latitud': destino.posicion.latitude,
          'longitud': destino.posicion.longitude,
        },
        'origen': {
          'latitud': widget.origen.latitude,
          'longitud': widget.origen.longitude,
        },
        'metros': widget.ruta.metros,
        'segundos': widget.duracion.inSeconds,
        'puntos': widget.ruta.puntos
            .map((p) => GeoPoint(p.latitude, p.longitude))
            .toList(),
        'fotos': subidas.map((f) => f.url).toList(),
        'fotosArchivos': subidas.map((f) => f.archivo).toList(),
        'creadoEn': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error guardando recorrido: $e');
      // si las fotos subieron pero Firestore falló, no quedan fotos huérfanas
      await FotosService.borrar(subidas.map((f) => f.archivo));
      if (!mounted) return;
      _mensaje('No se pudo guardar el viaje. Inténtalo otra vez.');
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return PopScope(
      // mientras sube, no se puede salir a medias
      canPop: !_guardando,

      child: Scaffold(
        body: Column(
          children: [
            // encabezado verde con "Omitir"
            Container(
              width: double.infinity,
              color: colors.primary,

              child: SafeArea(
                bottom: false,

                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppPadding.md,
                    AppPadding.xs,
                    AppPadding.xs,
                    AppPadding.lg,
                  ),

                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: colors.onPrimary,
                          ),
                          onPressed: _guardando
                              ? null
                              : () => _guardar(conDetalles: false),
                          child: const Text('OMITIR'),
                        ),
                      ),

                      Text(
                        '¡Acabas de terminar un\nincreíble viaje!',
                        textAlign: TextAlign.center,
                        style: text.titleLarge?.copyWith(
                          color: colors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // formulario
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppPadding.md),

                children: [
                  Text('Detalles', style: text.titleMedium),
                  const SizedBox(height: AppGap.component),

                  const _Etiqueta('Nombre del viaje'),
                  TextField(
                    controller: _nombre,
                    enabled: !_guardando,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Locurita del Juernes',
                    ),
                  ),
                  const SizedBox(height: AppGap.component),

                  const _Etiqueta('Comentario'),
                  TextField(
                    controller: _comentario,
                    enabled: !_guardando,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Vi a un zorro',
                    ),
                  ),
                  const SizedBox(height: AppGap.component),

                  const _Etiqueta('Tipo de bici'),
                  // chips, igual que "Dificultad" al guardar un lugar
                  Wrap(
                    spacing: AppGap.related,
                    runSpacing: AppGap.related,
                    children: [
                      for (final bici in kBicis.entries)
                        ChoiceChip(
                          // naranjo = bici, en toda la app
                          avatar: Icon(bici.value, color: colors.tertiary),
                          label: Text(bici.key),
                          selected: _bici == bici.key,
                          onSelected: _guardando
                              ? null
                              : (_) => setState(() => _bici = bici.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppGap.section),

                  Text('Califica el viaje', style: text.titleMedium),
                  const SizedBox(height: AppGap.component),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var i = 0; i < _caritas.length; i++)
                        _Carita(
                          icono: _caritas[i].$1,
                          texto: _caritas[i].$2,
                          seleccionada: _calificacion == i + 1,
                          // con una elegida, las otras se apagan
                          apagada:
                              _calificacion != null && _calificacion != i + 1,
                          // tocar la misma otra vez la quita
                          onTap: _guardando
                              ? null
                              : () => setState(
                                  () => _calificacion =
                                      _calificacion == i + 1 ? null : i + 1,
                                ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppGap.section),

                  Text('Fotos', style: text.titleMedium),
                  const SizedBox(height: AppGap.component),
                  FotosPicker(
                    nuevas: _fotos,
                    habilitado: !_guardando,
                    onAgregar: _agregarFotos,
                    onQuitar: (i) => setState(() => _fotos.removeAt(i)),
                  ),
                ],
              ),
            ),

            // guardar
            SafeArea(
              top: false,

              child: Padding(
                padding: const EdgeInsets.all(AppPadding.md),

                child: FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppGap.related),
      child: Text(
        texto,
        style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}

// carita para calificar: al elegirla se rellena el círculo y se marca el texto
class _Carita extends StatelessWidget {
  const _Carita({
    required this.icono,
    required this.texto,
    required this.seleccionada,
    required this.apagada,
    this.onTap,
  });

  final IconData icono;
  final String texto;
  final bool seleccionada;
  final bool apagada;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = seleccionada
        ? colors.primary
        : apagada
        ? colors.outlineVariant
        : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: seleccionada,
      label: 'Calificar: $texto',

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),

        child: Padding(
          padding: const EdgeInsets.all(AppPadding.sm),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(AppPadding.sm),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: seleccionada
                      ? colors.primaryContainer
                      : Colors.transparent,
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: seleccionada ? 1.15 : 1,
                  child: Icon(icono, size: 40, color: color),
                ),
              ),

              const SizedBox(height: AppGap.tight),

              Text(
                texto,
                style: text.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: seleccionada ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
