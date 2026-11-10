import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart'
    show GoogleMapsFlutterPlatform, PointOfInterestTapEvent;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'auth/auth_gate.dart';
import 'firebase_options.dart';
import 'theme/app_icons.dart';
import 'theme/theme.dart';
import 'views/filters_sheet.dart';
import 'views/map_header.dart';
import 'services/fotos_limite.dart';
import 'services/places_service.dart';
import 'views/place_card.dart';
import 'views/pre_trip.dart';
import 'views/save_route_sheet.dart';
import 'views/search.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize();
  }
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      // en web, el mouse también arrastra paneles y listas
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          ui.PointerDeviceKind.touch,
          ui.PointerDeviceKind.mouse,
          ui.PointerDeviceKind.stylus,
          ui.PointerDeviceKind.trackpad,
        },
      ),
      home: const AuthGate(child: HomeScreen()),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0 inicio, 1 mapa, 2 social, 3 perfil
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // contenido: cada pestaña es una vista de /views
      body: IndexedStack(
        index: _selectedIndex,

        children: const [
          _Pending(label: 'Inicio'),
          RutasScreen(),
          _Pending(label: 'Social'),
          _Pending(label: 'Perfil'),
        ],
      ),

      // botón principal (navegación)
      floatingActionButton: PointerInterceptor(
        child: FloatingActionButton(
          heroTag: 'navegacion',
          onPressed: () {},
          child: const Icon(Icons.navigation),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // bottom navigation bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,

        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        destinations: const [
          // inicio
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),

          // mapa
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),

          // social
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Social',
          ),

          // perfil
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// pestañas que todavía no se construyen
class _Pending extends StatelessWidget {
  const _Pending({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Center(child: Text(label, style: text.headlineMedium));
  }
}

class RutasScreen extends StatefulWidget {
  const RutasScreen({super.key});

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen> {
  // id del punto que se toca en el mapa mientras no se sepa si es un lugar real
  static const String _idPunto = 'punto_libre';
  static const double _panelMin = 0.14;
  static const double _panelAbierto = 0.6;
  final _panelController = DraggableScrollableController();

  final _mapKey = GlobalKey<_MapaRutasState>();
  final _places = PlacesService();
  // guardados de Firestore: llegan por la suscripción y quedan en el estado.
  // Lo filtrado y los marcadores se calculan UNA vez por cambio (_recalcular),
  // no en cada build: así abrir una card o mover el panel no recorre todo.
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _suscripcion;
  QuerySnapshot<Map<String, dynamic>>? _rutasSnapshot;
  bool _errorRutas = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filtradas = const [];
  Set<Marker> _marcadores = const {};
  FiltrosRutas _filtros = const FiltrosRutas();
  // marcadores del mapa: uno para lugares y otro para rutas
  BitmapDescriptor? _iconoLugar;
  BitmapDescriptor? _iconoRuta;

  // lo que está elegido en el mapa: un punto, un lugar real o una ruta guardada
  Lugar? _seleccion;

  @override
  void dispose() {
    _suscripcion?.cancel();
    _panelController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _crearIconos();
    _suscripcion = FirebaseFirestore.instance
        .collection('rutas')
        .snapshots()
        .listen(
          (datos) {
            if (!mounted) return;
            _rutasSnapshot = datos;
            _errorRutas = false;
            _recalcular();
            _sincronizarSeleccion();
          },
          onError: (Object error) {
            debugPrint('Error leyendo rutas: $error');
            if (mounted) setState(() => _errorRutas = true);
          },
        );
  }

  // filtra y arma los marcadores; se llama cuando cambian los datos,
  // los filtros o los íconos (nunca dentro de build)
  void _recalcular() {
    final filtradas = filtrarRutas(
      _rutasSnapshot?.docs ?? const [],
      filtros: _filtros,
    );

    final marcadores = <Marker>{};
    for (final doc in filtradas) {
      final ruta = doc.data();
      final lat = (ruta['latitud'] as num?)?.toDouble();
      final lng = (ruta['longitud'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      marcadores.add(
        Marker(
          markerId: MarkerId(doc.id),
          icon:
              (ruta['tipo'] == 'ruta' ? _iconoRuta : _iconoLugar) ??
              BitmapDescriptor.defaultMarker,
          position: LatLng(lat, lng),
          onTap: () => _seleccionarRuta(doc),
        ),
      );
    }

    setState(() {
      _filtradas = filtradas;
      _marcadores = marcadores;
    });
  }

  void _cambiarFiltros(FiltrosRutas nuevos) {
    _filtros = nuevos;
    _recalcular();
  }

  Future<void> _crearIconos() async {
    final lugar = await _crearIcono(AppIcons.lugar);
    final ruta = await _crearIcono(AppIcons.ruta);
    if (!mounted) return;
    _iconoLugar = lugar;
    _iconoRuta = ruta;
    _recalcular();
  }

  // marcador: círculo pequeño con borde blanco, como los íconos de lugares
  // de Google (30 px lógicos, dibujado al triple para que se vea nítido)
  Future<BitmapDescriptor?> _crearIcono(IconData icono) async {
    const double lado = 90;
    const double escala = 3;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const centro = Offset(lado / 2, lado / 2);

    canvas.drawCircle(
      centro,
      lado / 2,
      Paint()..color = appColorScheme.surface,
    );
    canvas.drawCircle(
      centro,
      lado / 2 - 4,
      Paint()..color = appColorScheme.primary,
    );

    final texto = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icono.codePoint),
        style: TextStyle(
          fontSize: 48,
          fontFamily: icono.fontFamily,
          package: icono.fontPackage,
          color: appColorScheme.onPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    texto.paint(
      canvas,
      Offset((lado - texto.width) / 2, (lado - texto.height) / 2),
    );

    final imagen = await recorder.endRecording().toImage(
      lado.toInt(),
      lado.toInt(),
    );
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    imagen.dispose();
    if (datos == null) return null;

    return BitmapDescriptor.bytes(
      datos.buffer.asUint8List(),
      imagePixelRatio: escala,
    );
  }

  // cada toque en el mapa invalida lo que se estaba buscando antes
  int _toques = 0;

  // toque en un ícono de Google: ese lugar exacto (por su placeId)
  Future<void> _seleccionarIcono(String placeId) async {
    final toque = ++_toques;
    debugPrint('Toque en ícono de Google: $placeId');

    try {
      var lugar = await _places.detalle(
        placeId,
        sesion: PlacesService.nuevaSesion(),
      );
      // la foto solo se pide para el lugar que de verdad quedó elegido
      if (lugar.fotoNombre != null) lugar = await LimiteFotos.aplicar(lugar);
      // si ya tocó otra cosa, este resultado quedó viejo
      if (!mounted || toque != _toques) return;

      setState(() => _seleccion = lugar);
      _mapKey.currentState?.centrar(lugar.posicion);
      // si ese lugar ya es una ruta guardada, se muestra como ruta
      _sincronizarSeleccion();
    } catch (e) {
      debugPrint('Error abriendo el ícono: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir ese lugar.')),
      );
    }
  }

  // toque en el mapa fuera de los íconos: un lugar pegado al dedo o,
  // si no hay, la calle de ese punto
  Future<void> _seleccionarPunto(LatLng posicion) async {
    _toques++;

    setState(() {
      _seleccion = Lugar(
        id: _idPunto,
        nombre: 'Buscando lugar…',
        direccion:
            '${posicion.latitude.toStringAsFixed(5)}, '
            '${posicion.longitude.toStringAsFixed(5)}',
        tipo: 'Ubicación',
        posicion: posicion,
      );
    });
    _mapKey.currentState?.centrar(posicion);

    Lugar? lugar;
    try {
      lugar = await _places.cercano(
        posicion,
        zoom: _mapKey.currentState?.zoom ?? 15,
      );
    } catch (e) {
      debugPrint('Error buscando lugar: $e');
    }
    try {
      lugar ??= await _places.calle(posicion);
    } catch (e) {
      debugPrint('Error buscando calle: $e');
    }

    if (!mounted) return;
    // si ya eligió otra cosa, este resultado quedó viejo
    bool vigente() {
      final actual = _seleccion;
      return actual != null &&
          actual.id == _idPunto &&
          actual.posicion == posicion;
    }

    if (!vigente()) return;

    // la foto solo se pide para el lugar que de verdad quedó elegido
    if (lugar != null && lugar.fotoNombre != null) {
      lugar = await LimiteFotos.aplicar(lugar);
      if (!mounted || !vigente()) return;
    }

    final actual = _seleccion!;
    setState(() {
      _seleccion =
          lugar ??
          Lugar(
            id: _idPunto,
            nombre: 'Punto seleccionado',
            direccion: actual.direccion,
            tipo: 'Ubicación',
            posicion: posicion,
          );
    });
    // si ese lugar ya es una ruta guardada, se muestra como ruta
    _sincronizarSeleccion();
  }

  // ruta guardada (desde su marcador o desde la lista): el mapa va hacia ella
  void _seleccionarRuta(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final lugar = Lugar.deRuta(doc.data(), doc.id);
    if (lugar == null) return;
    setState(() => _seleccion = lugar);
    _mapKey.currentState?.irA(lugar.posicion);
  }

  // la card sigue los cambios de Firestore: lugar guardado pasa a ruta,
  // ruta editada se actualiza y ruta eliminada se cierra
  void _sincronizarSeleccion() {
    final actual = _seleccion;
    final datos = _rutasSnapshot;
    if (!mounted || actual == null || datos == null) return;
    // mientras se busca el lugar tocado no se cambia nada
    if (actual.id == _idPunto && actual.nombre == 'Buscando lugar…') return;

    QueryDocumentSnapshot<Map<String, dynamic>>? encontrada;
    for (final doc in datos.docs) {
      final coincide = actual.esRuta
          ? doc.id == actual.idRuta
          : _mismaPosicion(doc.data(), actual.posicion);
      if (coincide) {
        encontrada = doc;
        break;
      }
    }

    if (encontrada == null) {
      // la ruta elegida ya no existe
      if (actual.esRuta) setState(() => _seleccion = null);
      return;
    }

    final lugar = Lugar.deRuta(encontrada.data(), encontrada.id);
    if (lugar != null) setState(() => _seleccion = lugar);
  }

  // la ruta guardada está en ese mismo punto
  bool _mismaPosicion(Map<String, dynamic> ruta, LatLng posicion) {
    const tolerancia = 0.000001;
    final latitud = (ruta['latitud'] as num?)?.toDouble();
    final longitud = (ruta['longitud'] as num?)?.toDouble();
    return latitud != null &&
        longitud != null &&
        (latitud - posicion.latitude).abs() < tolerancia &&
        (longitud - posicion.longitude).abs() < tolerancia;
  }

  Future<void> _guardarSeleccion() async {
    final lugar = _seleccion;
    if (lugar == null) return;

    final esPuntoLibre = lugar.id == _idPunto;
    final guardada = await mostrarGuardarRuta(
      context,
      lugar.posicion,
      tituloInicial: esPuntoLibre ? '' : lugar.nombre,
      descripcionInicial: esPuntoLibre ? '' : lugar.direccion,
    );
    if (!guardada || !mounted) return;

    setState(() => _seleccion = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lugar guardado correctamente'),
        behavior: SnackBarBehavior.fixed,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _comenzarViaje() {
    final destino = _seleccion;
    if (destino == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PreTripView(destino: destino)),
    );
  }

  // abre el buscador; lo elegido vuelve aquí y se muestra en este mismo mapa
  Future<void> _abrirBuscador() async {
    final lugar = await Navigator.push<Lugar>(
      context,
      MaterialPageRoute(builder: (context) => const SearchView()),
    );
    if (lugar == null || !mounted) return;

    setState(() => _seleccion = lugar);
    _mapKey.currentState?.irA(lugar.posicion);
    // si ese lugar ya es una ruta guardada, se muestra como ruta
    _sincronizarSeleccion();
  }

  // abre el panel de filtros y guarda lo que se elija
  Future<void> _abrirFiltros() async {
    final nuevos = await mostrarFiltros(context, _filtros);
    if (nuevos != null && mounted) _cambiarFiltros(nuevos);
  }

  // chip de la bici: elegir modo
  Future<void> _abrirModo() async {
    final nuevos = await mostrarModo(context, _filtros);
    if (nuevos != null && mounted) _cambiarFiltros(nuevos);
  }

  // tocar la manija o el título abre o cierra el panel
  void _alternarPanel() {
    if (!_panelController.isAttached) return;
    final abierto = _panelController.size > _panelMin + 0.05;
    _panelController.animateTo(
      abierto ? _panelMin : _panelAbierto,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // panel con todas las rutas guardadas; tocar una lleva el mapa hasta ella
  Widget _panelRutas() {
    final colors = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      controller: _panelController,
      initialChildSize: _panelMin,
      minChildSize: _panelMin,
      maxChildSize: 0.85,
      snap: true,
      builder: (context, scrollController) {
        return PointerInterceptor(
          child: Material(
            color: colors.surface,
            elevation: 3,
            clipBehavior: Clip.antiAlias,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            child: _listaGuardados(scrollController),
          ),
        );
      },
    );
  }

  // contenido del panel. ListView.builder solo construye las filas visibles.
  Widget _listaGuardados(ScrollController scrollController) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final rutas = _filtradas;
    final cargando = _rutasSnapshot == null && !_errorRutas;
    final titulo = _filtros.activo
        ? 'Guardados filtrados'
        : 'Lugares y rutas guardados';

    // manija y título: tocarlos abre o cierra el panel
    final encabezado = InkWell(
      onTap: _alternarPanel,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(height: AppSpacing.space200),
          Row(
            children: [
              Expanded(
                child: Text(
                  cargando ? titulo : '$titulo (${rutas.length})',
                  style: text.titleLarge,
                ),
              ),
              const Icon(Icons.unfold_more),
            ],
          ),
          const SizedBox(height: AppSpacing.space200),
        ],
      ),
    );

    // sin filas: encabezado + mensaje
    Widget? mensaje;
    if (_errorRutas) {
      mensaje = const Text('No se pudieron cargar tus guardados.');
    } else if (cargando) {
      mensaje = const Center(child: CircularProgressIndicator());
    } else if (rutas.isEmpty) {
      mensaje = _filtros.activo
          ? Row(
              children: [
                const Expanded(child: Text('No hay guardados con esos filtros.')),
                TextButton(
                  onPressed: () => _cambiarFiltros(const FiltrosRutas()),
                  child: const Text('Quitar filtros'),
                ),
              ],
            )
          : const Text(
              'Todavía no guardas nada. Toca un lugar del mapa para guardar el primero.',
            );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space400,
        AppSpacing.space200,
        AppSpacing.space400,
        // deja libre la barra de navegación y el botón central
        AppSpacing.space1100,
      ),
      itemCount: 1 + (mensaje != null ? 1 : rutas.length),
      itemBuilder: (context, i) {
        if (i == 0) return encabezado;
        if (mensaje != null) return mensaje;
        return _filaGuardado(rutas[i - 1]);
      },
    );
  }

  // una fila del panel: mismo ícono que su marcador; editar/eliminar en un menú
  // (como el ListTile con PopupMenuButton de componentes del profe)
  Widget _filaGuardado(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final colors = Theme.of(context).colorScheme;
    final ruta = doc.data();
    final detalle = [
      ruta['bici'] as String? ?? '',
      ruta['dificultad'] as String? ?? '',
      ruta['descripcion'] as String? ?? '',
    ].where((parte) => parte.isNotEmpty).join(' · ');

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          child: Icon(AppIcons.deTipo(ruta['tipo'] as String?)),
        ),
        title: Text(ruta['titulo'] as String? ?? 'Sin título'),
        subtitle: detalle.isEmpty
            ? null
            : Text(detalle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton<String>(
          tooltip: 'Opciones',
          onSelected: (opcion) => opcion == 'editar'
              ? editarRuta(context, doc)
              : eliminarRuta(context, doc),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'editar',
              child: ListTile(
                leading: Icon(AppIcons.editar),
                title: Text('Editar'),
              ),
            ),
            PopupMenuItem(
              value: 'eliminar',
              child: ListTile(
                leading: Icon(AppIcons.eliminar),
                title: Text('Eliminar'),
              ),
            ),
          ],
        ),
        onTap: () => _seleccionarRuta(doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seleccion = _seleccion;

    return Stack(
      children: [
        // mapa a pantalla completa
        Positioned.fill(
          child: _MapaRutas(
            key: _mapKey,
            marcadores: _marcadores,
            // el pin rojo solo para puntos y lugares; las rutas ya tienen su marcador
            posicionSeleccionada: seleccion != null && !seleccion.esRuta
                ? seleccion.posicion
                : null,
            onTocar: _seleccionarPunto,
            onTocarIcono: _seleccionarIcono,
          ),
        ),

        // buscador + chips
        Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MapHeader(
                onSearch: _abrirBuscador,
                onFilters: _abrirFiltros,
                onModo: _abrirModo,
                bici: _filtros.bici,
                filtrosActivos: _filtros.cantidad,
              ),
            ],
          ),
        ),

        // sin nada elegido: lista de rutas; con algo elegido: su card
        if (seleccion == null)
          _panelRutas()
        else
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              // abajo deja espacio para el botón de navegación
              padding: const EdgeInsets.fromLTRB(
                AppPadding.md,
                AppPadding.md,
                AppPadding.md,
                AppSpacing.space900,
              ),
              child: PlaceCard(
                title: seleccion.nombre,
                category: seleccion.tipo ?? 'Lugar',
                // guardado: pin o ruta; de Google / punto suelto: pin vacío
                categoryIcon: !seleccion.esRuta
                    ? AppIcons.lugarSinGuardar
                    : (seleccion.tipo ?? '').startsWith('Ruta')
                    ? AppIcons.ruta
                    : AppIcons.lugar,
                note: seleccion.direccion,
                fotoUrl: seleccion.fotoUrl,
                fotoAutor: seleccion.fotoAutor,
                onClose: () => setState(() => _seleccion = null),
                // una ruta ya guardada no se vuelve a guardar
                onSaveRoute: seleccion.esRuta ? null : _guardarSeleccion,
                onStart: _comenzarViaje,
              ),
            ),
          ),
      ],
    );
  }
}

class _MapaRutas extends StatefulWidget {
  const _MapaRutas({
    super.key,
    required this.marcadores,
    required this.posicionSeleccionada,
    required this.onTocar,
    required this.onTocarIcono,
  });

  final Set<Marker> marcadores;
  final LatLng? posicionSeleccionada;
  final ValueChanged<LatLng> onTocar;
  // recibe el placeId del ícono de Google que se tocó
  final ValueChanged<String> onTocarIcono;

  @override
  State<_MapaRutas> createState() => _MapaRutasState();
}

class _MapaRutasState extends State<_MapaRutas> {
  GoogleMapController? _controller;
  StreamSubscription<PointOfInterestTapEvent>? _toquesIconos;
  double _zoom = 11;

  double get zoom => _zoom;

  // acerca el mapa a una ruta
  Future<void> irA(LatLng posicion) async {
    await _controller?.animateCamera(CameraUpdate.newLatLngZoom(posicion, 15));
  }

  // centra el punto sin cambiar el zoom
  Future<void> centrar(LatLng posicion) async {
    await _controller?.animateCamera(CameraUpdate.newLatLng(posicion));
  }

  @override
  void dispose() {
    _toquesIconos?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(-33.4489, -70.6693),
        zoom: 11,
      ),
      mapType: MapType.normal,
      markers: {
        ...widget.marcadores,
        if (widget.posicionSeleccionada != null)
          Marker(
            markerId: const MarkerId('seleccion'),
            position: widget.posicionSeleccionada!,
          ),
      },
      onMapCreated: (controller) {
        _controller = controller;
        // toque en íconos de Google (GoogleMap aún no tiene este callback)
        _toquesIconos?.cancel();
        _toquesIconos = GoogleMapsFlutterPlatform.instance
            .onPointOfInterestTap(mapId: controller.mapId)
            .listen((evento) => widget.onTocarIcono(evento.value.value));
      },
      onTap: widget.onTocar,
      onCameraMove: (camara) => _zoom = camara.zoom,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
    );
  }
}
