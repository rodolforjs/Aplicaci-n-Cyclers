import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../services/fotos_service.dart';
import '../services/places_service.dart';
import '../theme/app_icons.dart';
import '../theme/theme.dart';
import 'filters_sheet.dart';
import 'fotos_picker.dart';

// lo que se puede guardar desde este formulario (campo "tipo" en Firestore)
const String kTipoLugar = 'lugar';
const String kTipoRuta = 'ruta';

// formulario para guardar en Firestore (colección "rutas"):
//  - un LUGAR (tipo: 'lugar'): solo un punto del mapa. Se guarda desde la card
//    de un lugar.
//  - una RUTA (tipo: 'ruta'): el camino calculado hasta ese punto. Se guarda
//    desde "Precomienzo Viaje"; en datosRuta llegan origen, distancia y puntos.
// Los viajes ya hechos se guardan aparte, en "recorridos" (ver end_trip.dart).
// Con idRuta edita ese documento en vez de crear uno nuevo.
// Devuelve true si se guardó.
Future<bool> mostrarGuardarRuta(
  BuildContext context,
  LatLng posicion, {
  String tipo = kTipoLugar,
  Map<String, dynamic> datosRuta = const {},
  String? idRuta,
  String tituloInicial = '',
  String descripcionInicial = '',
  String dificultadInicial = 'Media',
  String? biciInicial,
  List<String> fotosIniciales = const [],
}) async {
  final guardada = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    // en web, evita que los toques del formulario lleguen al mapa de abajo
    builder: (sheetContext) => PointerInterceptor(
      child: _GuardarRutaSheet(
        posicion: posicion,
        tipo: tipo,
        datosRuta: datosRuta,
        idRuta: idRuta,
        tituloInicial: tituloInicial,
        descripcionInicial: descripcionInicial,
        dificultadInicial: dificultadInicial,
        biciInicial: biciInicial,
        fotosIniciales: fotosIniciales,
      ),
    ),
  );
  return guardada ?? false;
}

// editar: abre el mismo formulario de guardar, con los datos de la ruta.
// Lo usan el buscador y el panel de rutas del mapa.
Future<void> editarRuta(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) async {
  final ruta = doc.data();
  final lugar = Lugar.deRuta(ruta, doc.id);
  if (lugar == null) return;

  await mostrarGuardarRuta(
    context,
    lugar.posicion,
    // los guardados antes de separar lugar y ruta no tienen tipo: son lugares
    tipo: ruta['tipo'] as String? ?? kTipoLugar,
    idRuta: doc.id,
    tituloInicial: ruta['titulo'] as String? ?? '',
    descripcionInicial: ruta['descripcion'] as String? ?? '',
    dificultadInicial: ruta['dificultad'] as String? ?? 'Media',
    biciInicial: ruta['bici'] as String?,
    fotosIniciales: List<String>.from(ruta['fotos'] as List? ?? const []),
  );
}

// eliminar: pide confirmación, borra el documento de Firestore y sus fotos
Future<void> eliminarRuta(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) async {
  final mensajes = ScaffoldMessenger.of(context);
  final esRuta = doc.data()['tipo'] == kTipoRuta;
  final nombre = esRuta ? 'ruta' : 'lugar';
  final titulo =
      doc.data()['titulo'] as String? ?? (esRuta ? 'esta ruta' : 'este lugar');

  final confirmar = await showDialog<bool>(
    context: context,
    // en web, evita que los toques del diálogo lleguen al mapa de abajo
    builder: (dialogContext) => PointerInterceptor(
      child: AlertDialog(
        title: Text('Eliminar $nombre'),
        content: Text('¿Eliminar "$titulo"? No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ),
  );
  if (confirmar != true) return;

  try {
    final archivos = List<String>.from(
      doc.data()['fotosArchivos'] as List? ?? const [],
    );
    await doc.reference.delete();
    // las fotos se borran después: si esto falla, la ruta igual quedó eliminada
    await FotosService.borrar(archivos);
    mensajes.showSnackBar(
      SnackBar(content: Text(esRuta ? 'Ruta eliminada.' : 'Lugar eliminado.')),
    );
  } catch (e) {
    debugPrint('Error eliminando ruta: $e');
    mensajes.showSnackBar(
      SnackBar(content: Text('No se pudo eliminar el $nombre.')),
    );
  }
}

class _GuardarRutaSheet extends StatefulWidget {
  const _GuardarRutaSheet({
    required this.posicion,
    required this.tipo,
    required this.datosRuta,
    required this.idRuta,
    required this.tituloInicial,
    required this.descripcionInicial,
    required this.dificultadInicial,
    required this.biciInicial,
    required this.fotosIniciales,
  });

  final LatLng posicion;
  // kTipoLugar o kTipoRuta
  final String tipo;
  // solo rutas nuevas: origen, metros, puntos...
  final Map<String, dynamic> datosRuta;
  // null = ruta nueva; con id = editar esa ruta
  final String? idRuta;
  final String tituloInicial;
  final String descripcionInicial;
  final String dificultadInicial;
  // solo rutas: para qué bici es (sirve para el filtro de modo)
  final String? biciInicial;
  // URLs de las fotos que ya tiene (al editar)
  final List<String> fotosIniciales;

  @override
  State<_GuardarRutaSheet> createState() => _GuardarRutaSheetState();
}

class _GuardarRutaSheetState extends State<_GuardarRutaSheet> {
  // los controladores viven y mueren con el formulario
  late final _titulo = TextEditingController(text: widget.tituloInicial);
  late final _descripcion = TextEditingController(
    text: widget.descripcionInicial,
  );
  final _formKey = GlobalKey<FormState>();
  bool _guardando = false;
  late String _dificultad = widget.dificultadInicial;
  late String _bici = widget.biciInicial ?? kBicis.keys.first;
  // fotos elegidas en este formulario (se suben al guardar)
  final List<FotoNueva> _fotos = [];

  bool get _editando => widget.idRuta != null;
  bool get _esRuta => widget.tipo == kTipoRuta;

  // "Nuevo lugar", "Editar ruta"...
  String get _tituloSheet {
    if (_esRuta) return _editando ? 'Editar ruta' : 'Nueva ruta';
    return _editando ? 'Editar lugar' : 'Nuevo lugar';
  }

  String get _textoBoton {
    if (_editando) return 'Guardar cambios';
    return _esRuta ? 'Guardar ruta' : 'Guardar lugar';
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.fixed),
    );
  }

  Future<void> _agregarFotos() async {
    final libres =
        FotosService.maximo - widget.fotosIniciales.length - _fotos.length;
    try {
      final elegidas = await FotosService.elegir(cuantas: libres);
      if (!mounted || elegidas.isEmpty) return;
      setState(() => _fotos.addAll(elegidas));
    } catch (e) {
      debugPrint('Error eligiendo fotos: $e');
      if (mounted) _mensaje('No se pudieron abrir las fotos.');
    }
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final rutas = FirebaseFirestore.instance.collection('rutas');
    // el id se crea antes, así las fotos quedan en una carpeta con ese id
    final doc = _editando ? rutas.doc(widget.idRuta) : rutas.doc();
    var subidas = <FotoSubida>[];

    try {
      subidas = await FotosService.subir(
        _esRuta ? 'rutas' : 'lugares',
        doc.id,
        _fotos,
      );

      final datos = {
        'titulo': _titulo.text.trim(),
        'descripcion': _descripcion.text.trim(),
        'dificultad': _dificultad,
        if (_esRuta) 'bici': _bici,
        // arrayUnion suma las nuevas sin borrar las que ya estaban
        if (subidas.isNotEmpty) ...{
          'fotos': FieldValue.arrayUnion(subidas.map((f) => f.url).toList()),
          'fotosArchivos': FieldValue.arrayUnion(
            subidas.map((f) => f.archivo).toList(),
          ),
        },
      };

      if (_editando) {
        await doc.update(datos);
      } else {
        await doc.set({
          ...datos,
          ...widget.datosRuta,
          'tipo': widget.tipo,
          'usuario': FirebaseAuth.instance.currentUser?.uid,
          'latitud': widget.posicion.latitude,
          'longitud': widget.posicion.longitude,
          'creadoEn': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error guardando ruta: $e');
      // si las fotos subieron pero Firestore falló, no quedan fotos huérfanas
      await FotosService.borrar(subidas.map((f) => f.archivo));
      if (!mounted) return;
      _mensaje(
        'No se pudo guardar ${_esRuta ? 'la ruta' : 'el lugar'}. '
        'Inténtalo otra vez.',
      );
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space400,
        0,
        AppSpacing.space400,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.space400,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ícono + título y cerrar
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.primary,
                    child: Icon(_esRuta ? AppIcons.ruta : AppIcons.lugar),
                  ),
                  const SizedBox(width: AppSpacing.space300),
                  Expanded(
                    child: Text(_tituloSheet, style: text.titleLarge),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close),
                    onPressed: _guardando
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space200),
              TextFormField(
                controller: _titulo,
                autofocus: true,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa un título'
                    : null,
              ),
              const SizedBox(height: AppSpacing.space400),
              TextFormField(
                controller: _descripcion,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.space400),
              Text('Dificultad', style: text.titleMedium),
              const SizedBox(height: AppSpacing.space200),
              Wrap(
                spacing: AppSpacing.space200,
                children: [
                  for (final d in kDificultades)
                    ChoiceChip(
                      avatar: Icon(kIconosDificultad[d]),
                      label: Text(d),
                      selected: _dificultad == d,
                      onSelected: _guardando
                          ? null
                          : (_) => setState(() => _dificultad = d),
                    ),
                ],
              ),
              // una ruta es para un tipo de bici; un lugar sirve para todas
              if (_esRuta) ...[
                const SizedBox(height: AppSpacing.space400),
                Text('Bici', style: text.titleMedium),
                const SizedBox(height: AppSpacing.space200),
                Wrap(
                  spacing: AppSpacing.space200,
                  runSpacing: AppSpacing.space200,
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
              ],
              const SizedBox(height: AppSpacing.space400),
              Text('Fotos', style: text.titleMedium),
              const SizedBox(height: AppSpacing.space200),
              FotosPicker(
                nuevas: _fotos,
                guardadas: widget.fotosIniciales,
                habilitado: !_guardando,
                onAgregar: _agregarFotos,
                onQuitar: (i) => setState(() => _fotos.removeAt(i)),
              ),
              const SizedBox(height: AppSpacing.space600),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _guardando
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space200),
                  Expanded(
                    child: FilledButton(
                      onPressed: _guardando ? null : _guardar,
                      child: _guardando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_textoBoton),
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
