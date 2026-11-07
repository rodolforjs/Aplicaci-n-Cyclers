import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/fotos_limite.dart';
import '../services/places_service.dart';
import '../theme/theme.dart';
import 'filters_sheet.dart';
import 'place_tile.dart';
import 'save_route_sheet.dart';
import 'search_field.dart';

// pantalla "Buscador Abierto": busca entre tus rutas (Firestore) y entre
// lugares reales (Google Places). Lo elegido vuelve al mapa principal
// (Navigator.pop con el Lugar), que lo muestra en su card.
class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  // espera para no consultar a Google en cada letra
  static const Duration _pausaBusqueda = Duration(milliseconds: 400);
  static const int _letrasMinimas = 3;

  final _busquedaController = TextEditingController();
  final _places = PlacesService();
  // Firestore no repite el último dato a quien se suscribe tarde: se guarda aquí
  final _controlador =
      StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _suscripcion;
  QuerySnapshot<Map<String, dynamic>>? _rutasSnapshot;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _rutasStream =
      _controlador.stream;

  String _busqueda = '';
  Timer? _espera;
  String _sesion = PlacesService.nuevaSesion();
  List<LugarSugerido> _lugares = const [];
  bool _buscandoLugares = false;
  bool _errorLugares = false;

  @override
  void initState() {
    super.initState();
    _suscripcion = FirebaseFirestore.instance
        .collection('rutas')
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .listen(
          (datos) {
            _rutasSnapshot = datos;
            _controlador.add(datos);
          },
          onError: (Object error) {
            debugPrint('Error leyendo rutas: $error');
            if (_controlador.hasListener) _controlador.addError(error);
          },
        );
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    _controlador.close();
    _espera?.cancel();
    _busquedaController.dispose();
    super.dispose();
  }

  void _alEscribir(String valor) {
    final texto = valor.trim();
    _espera?.cancel();

    setState(() {
      _busqueda = texto.toLowerCase();
      _errorLugares = false;
      _buscandoLugares = texto.length >= _letrasMinimas;
      if (texto.length < _letrasMinimas) _lugares = const [];
    });

    if (texto.length >= _letrasMinimas) {
      _espera = Timer(_pausaBusqueda, () => _buscarLugares(texto));
    }
  }

  Future<void> _buscarLugares(String texto) async {
    try {
      final resultado = await _places.autocompletar(texto, sesion: _sesion);
      // si ya escribió otra cosa, este resultado quedó viejo
      if (!mounted || texto.toLowerCase() != _busqueda) return;
      setState(() {
        _lugares = resultado;
        _buscandoLugares = false;
      });
    } catch (e) {
      debugPrint('Error buscando lugares: $e');
      if (!mounted) return;
      setState(() {
        _buscandoLugares = false;
        _errorLugares = true;
      });
    }
  }

  Future<void> _abrirLugar(LugarSugerido sugerido) async {
    final navigator = Navigator.of(context);
    final mensajes = ScaffoldMessenger.of(context);

    try {
      final lugar = await LimiteFotos.aplicar(
        await _places.detalle(sugerido.id, sesion: _sesion),
      );
      if (!mounted) return;
      // la elección cierra la sesión de búsqueda
      _sesion = PlacesService.nuevaSesion();
      // vuelve al mapa con el lugar elegido
      navigator.pop(lugar);
    } catch (e) {
      debugPrint('Error abriendo lugar: $e');
      mensajes.showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el lugar. Inténtalo otra vez.'),
        ),
      );
    }
  }

  // una ruta como fila; al tocarla vuelve al mapa con esa ruta.
  // El menú de la derecha permite editarla o eliminarla.
  Widget _filaRuta(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final ruta = doc.data();
    final colors = Theme.of(context).colorScheme;
    final descripcion = ruta['descripcion'] as String? ?? '';
    final dificultad = ruta['dificultad'] as String?;

    return PlaceTile(
      icon: Icons.hiking,
      iconColor: colors.primary,
      iconBackground: colors.primaryContainer,
      title: ruta['titulo'] as String? ?? 'Sin título',
      subtitle: descripcion.isNotEmpty ? descripcion : dificultad,
      onTap: () => Navigator.pop(context, Lugar.deRuta(ruta, doc.id)),
      trailing: PopupMenuButton<String>(
        tooltip: 'Opciones',
        onSelected: (opcion) =>
            opcion == 'editar'
            ? editarRuta(context, doc)
            : eliminarRuta(context, doc),
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'editar', child: Text('Editar')),
          PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
        ],
      ),
    );
  }

  // rutas que coinciden con lo escrito
  Widget _rutasEncontradas() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      initialData: _rutasSnapshot,
      stream: _rutasStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('No se pudieron cargar las rutas.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = filtrarRutas(snapshot.data!.docs, busqueda: _busqueda);
        if (docs.isEmpty) return const Text('No se encontraron rutas.');

        return Column(children: docs.map((doc) => _filaRuta(doc)).toList());
      },
    );
  }

  // lugares reales que sugiere Google
  Widget _lugaresEncontrados() {
    final colors = Theme.of(context).colorScheme;

    if (_busqueda.length < _letrasMinimas) {
      return const Text('Escribe al menos 3 letras para buscar lugares.');
    }
    if (_buscandoLugares) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorLugares) {
      return const Text('No se pudieron cargar los lugares.');
    }
    if (_lugares.isEmpty) return const Text('No se encontraron lugares.');

    return Column(
      children: _lugares.map((lugar) {
        return PlaceTile(
          icon: Icons.place_outlined,
          iconColor: colors.tertiary,
          iconBackground: colors.tertiaryContainer,
          title: lugar.titulo,
          subtitle: lugar.detalle.isEmpty ? null : lugar.detalle,
          onTap: () => _abrirLugar(lugar),
        );
      }).toList(),
    );
  }

  // sin texto: las últimas rutas guardadas
  Widget _rutasRecientes() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      initialData: _rutasSnapshot,
      stream: _rutasStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('No se pudieron cargar las rutas.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.take(3).toList();
        if (docs.isEmpty) return const Text('Todavía no hay rutas guardadas.');

        return Column(children: docs.map((doc) => _filaRuta(doc)).toList());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppMargin.md,
            AppMargin.lg,
            AppMargin.md,
            AppMargin.md,
          ),

          children: [
            // campo de búsqueda
            SearchField(
              hint: 'Busca lugares o rutas',
              autofocus: true,
              controller: _busquedaController,
              onChanged: _alEscribir,
              onBack: () => Navigator.pop(context),
            ),

            const SizedBox(height: AppGap.component),

            if (_busqueda.isNotEmpty) ...[
              Text('Rutas', style: text.titleMedium),
              const SizedBox(height: AppGap.related),
              _rutasEncontradas(),

              const SizedBox(height: AppGap.component),

              Text('Lugares', style: text.titleMedium),
              const SizedBox(height: AppGap.related),
              _lugaresEncontrados(),
            ] else ...[
              Text('Rutas recientes', style: text.titleMedium),
              const SizedBox(height: AppGap.related),
              _rutasRecientes(),
            ],
          ],
        ),
      ),
    );
  }
}
