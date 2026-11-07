import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../services/places_service.dart';
import '../theme/theme.dart';
import 'filters_sheet.dart';

// formulario para guardar una ruta en el punto indicado (Firestore).
// Con idRuta edita esa ruta en vez de crear una nueva.
// Devuelve true si se guardó.
Future<bool> mostrarGuardarRuta(
  BuildContext context,
  LatLng posicion, {
  String? idRuta,
  String tituloInicial = '',
  String descripcionInicial = '',
  String dificultadInicial = 'Media',
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
        idRuta: idRuta,
        tituloInicial: tituloInicial,
        descripcionInicial: descripcionInicial,
        dificultadInicial: dificultadInicial,
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
    idRuta: doc.id,
    tituloInicial: ruta['titulo'] as String? ?? '',
    descripcionInicial: ruta['descripcion'] as String? ?? '',
    dificultadInicial: ruta['dificultad'] as String? ?? 'Media',
  );
}

// eliminar: pide confirmación y borra el documento de Firestore
Future<void> eliminarRuta(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) async {
  final mensajes = ScaffoldMessenger.of(context);
  final titulo = doc.data()['titulo'] as String? ?? 'esta ruta';

  final confirmar = await showDialog<bool>(
    context: context,
    // en web, evita que los toques del diálogo lleguen al mapa de abajo
    builder: (dialogContext) => PointerInterceptor(
      child: AlertDialog(
        title: const Text('Eliminar ruta'),
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
    await doc.reference.delete();
    mensajes.showSnackBar(const SnackBar(content: Text('Ruta eliminada.')));
  } catch (e) {
    debugPrint('Error eliminando ruta: $e');
    mensajes.showSnackBar(
      const SnackBar(content: Text('No se pudo eliminar la ruta.')),
    );
  }
}

class _GuardarRutaSheet extends StatefulWidget {
  const _GuardarRutaSheet({
    required this.posicion,
    required this.idRuta,
    required this.tituloInicial,
    required this.descripcionInicial,
    required this.dificultadInicial,
  });

  final LatLng posicion;
  // null = ruta nueva; con id = editar esa ruta
  final String? idRuta;
  final String tituloInicial;
  final String descripcionInicial;
  final String dificultadInicial;

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

  bool get _editando => widget.idRuta != null;

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      final rutas = FirebaseFirestore.instance.collection('rutas');
      final datos = {
        'titulo': _titulo.text.trim(),
        'descripcion': _descripcion.text.trim(),
        'dificultad': _dificultad,
      };

      if (_editando) {
        // editar: solo cambian los textos y la dificultad
        await rutas.doc(widget.idRuta).update(datos);
      } else {
        await rutas.add({
          ...datos,
          'latitud': widget.posicion.latitude,
          'longitud': widget.posicion.longitude,
          'creadoEn': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error guardando ruta: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la ruta. Inténtalo otra vez.'),
          behavior: SnackBarBehavior.fixed,
        ),
      );
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // título y cerrar
              Row(
                children: [
                  Expanded(child: Text(
                      _editando ? 'Editar ruta' : 'Nueva ruta',
                      style: text.titleLarge,
                    )),
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
                      label: Text(d),
                      selected: _dificultad == d,
                      onSelected: _guardando
                          ? null
                          : (_) => setState(() => _dificultad = d),
                    ),
                ],
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
                          : Text(_editando ? 'Guardar cambios' : 'Guardar ruta'),
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
