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
  // Firestore no repite el último dato a quien se suscribe tarde (por ejemplo,
  // el panel cuando vuelve a aparecer): se guarda aquí y se entrega como inicial
  final _controlador =
      StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _suscripcion;
  QuerySnapshot<Map<String, dynamic>>? _rutasSnapshot;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _rutasStream =
      _controlador.stream;
  FiltrosRutas _filtros = const FiltrosRutas();
  BitmapDescriptor? _iconoRuta;

  // lo que está elegido en el mapa: un punto, un lugar real o una ruta guardada
  Lugar? _seleccion;

  @override
  void dispose() {
    _suscripcion?.cancel();
    _controlador.close();
    _panelController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _crearIconoRuta();
    _suscripcion = FirebaseFirestore.instance
        .collection('rutas')
        .snapshots()
        .listen(
          (datos) {
            _rutasSnapshot = datos;
            _controlador.add(datos);
            _sincronizarSeleccion();
          },
          onError: (Object error) {
            debugPrint('Error leyendo rutas: $error');
            if (_controlador.hasListener) _controlador.addError(error);
          },
        );
  }

  // marcador de ruta: círculo pequeño con borde blanco, como los íconos de
  // lugares de Google (30 px lógicos, dibujado al triple para que se vea nítido)
  Future<void> _crearIconoRuta() async {
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

    const icono = Icons.landscape;
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
    if (datos == null || !mounted) return;

    setState(() {
      _iconoRuta = BitmapDescriptor.bytes(
        datos.buffer.asUint8List(),
        imagePixelRatio: escala,
      );
    });
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
        content: Text('Ruta guardada correctamente'),
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
    if (nuevos != null && mounted) setState(() => _filtros = nuevos);
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
    final text = Theme.of(context).textTheme;
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
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              initialData: _rutasSnapshot,
              stream: _rutasStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint(
                    'Error leyendo rutas del panel: ${snapshot.error}',
                  );
                }
                final rutas = filtrarRutas(
                  snapshot.data?.docs ?? [],
                  filtros: _filtros,
                );
                final titulo = _filtros.activo
                    ? 'Rutas filtradas'
                    : 'Rutas guardadas';

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space400,
                    AppSpacing.space200,
                    AppSpacing.space400,
                    AppSpacing.space400,
                  ),
                  children: [
                    // manija y título: tocarlos abre o cierra el panel
                    InkWell(
                      onTap: _alternarPanel,
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space200),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  snapshot.hasData
                                      ? '$titulo (${rutas.length})'
                                      : titulo,
                                  style: text.titleLarge,
                                ),
                              ),
                              const Icon(Icons.unfold_more),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space200),
                        ],
                      ),
                    ),
                    if (snapshot.hasError)
                      const Text('No se pudieron cargar las rutas.')
                    else if (!snapshot.hasData)
                      const Center(child: CircularProgressIndicator())
                    else if (rutas.isEmpty)
                      Text(
                        _filtros.activo
                            ? 'No hay rutas con esos filtros.'
                            : 'Todavía no hay rutas guardadas. Toca un lugar del mapa para guardar la primera.',
                      )
                    else
                      ...rutas.map((doc) {
                        final ruta = doc.data();
                        final detalle = [
                          ruta['dificultad'] as String? ?? '',
                          ruta['descripcion'] as String? ?? '',
                        ].where((parte) => parte.isNotEmpty).join(' · ');

                        return Card(
                          child: ListTile(
                            // mismo ícono que el marcador del mapa
                            leading: CircleAvatar(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              child: const Icon(Icons.landscape),
                            ),
                            title: Text(
                              ruta['titulo'] as String? ?? 'Sin título',
                            ),
                            subtitle: detalle.isEmpty
                                ? null
                                : Text(
                                    detalle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            // editar y eliminar
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => editarRuta(context, doc),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => eliminarRuta(context, doc),
                                ),
                              ],
                            ),
                            onTap: () => _seleccionarRuta(doc),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final seleccion = _seleccion;

    return Stack(
      children: [
        // mapa a pantalla completa
        Positioned.fill(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            initialData: _rutasSnapshot,
            stream: _rutasStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('Error leyendo rutas: ${snapshot.error}');
              }
              final marcadores = <Marker>{};
              if (snapshot.hasData) {
                for (final doc in filtrarRutas(
                  snapshot.data!.docs,
                  filtros: _filtros,
                )) {
                  final ruta = doc.data();
                  final lat = (ruta['latitud'] as num?)?.toDouble();
                  final lng = (ruta['longitud'] as num?)?.toDouble();
                  if (lat == null || lng == null) continue;
                  marcadores.add(
                    Marker(
                      markerId: MarkerId(doc.id),
                      icon: _iconoRuta ?? BitmapDescriptor.defaultMarker,
                      position: LatLng(lat, lng),
                      onTap: () => _seleccionarRuta(doc),
                    ),
                  );
                }
              }
              return _MapaRutas(
                key: _mapKey,
                marcadores: marcadores,
                // el pin rojo solo para puntos y lugares; las rutas ya tienen su marcador
                posicionSeleccionada: seleccion != null && !seleccion.esRuta
                    ? seleccion.posicion
                    : null,
                onTocar: _seleccionarPunto,
                onTocarIcono: _seleccionarIcono,
              );
            },
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
                categoryIcon: seleccion.esRuta
                    ? Icons.landscape
                    : Icons.place_outlined,
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
