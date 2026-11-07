import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/places_service.dart';
import '../services/routes_service.dart';
import '../services/ubicacion_service.dart';
import '../theme/theme.dart';
import 'map_controls.dart';
import 'route_card.dart';
import 'route_map.dart';
import 'save_route_sheet.dart';
import 'trip.dart';
import 'trip_metrics.dart';

// pantalla "Precomienzo Viaje": la ruta real desde tu ubicación hasta el destino
class PreTripView extends StatefulWidget {
  const PreTripView({super.key, required this.destino});

  final Lugar destino;

  @override
  State<PreTripView> createState() => _PreTripViewState();
}

class _PreTripViewState extends State<PreTripView> {
  // alto aproximado de la card de abajo, para que la ruta no quede tapada
  static const double _altoCard = 260;

  // relieve y ver todo el recorrido
  static const List<IconData> _herramientas = [
    Icons.terrain,
    Icons.zoom_out_map,
  ];

  final _mapaKey = GlobalKey<MapaRutaState>();
  final _ubicacion = UbicacionService();
  final _rutas = RoutesService();

  LatLng? _origen;
  RutaCalculada? _ruta;
  String? _error;
  bool _cargando = true;
  MapType _tipo = MapType.normal;
  // ya se guardó en esta pantalla: no se vuelve a guardar
  bool _guardada = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // ubicación actual -> ruta hasta el destino
  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final origen = await _ubicacion.actual();
      if (!mounted) return;
      setState(() => _origen = origen);

      final ruta = await _rutas.calcular(origen, widget.destino.posicion);
      if (!mounted) return;
      setState(() {
        _ruta = ruta;
        _cargando = false;
      });
    } on UbicacionException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('Error calculando la ruta: $e');
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo calcular la ruta.';
        _cargando = false;
      });
    }
  }

  Future<void> _guardar() async {
    final destino = widget.destino;
    final guardada = await mostrarGuardarRuta(
      context,
      destino.posicion,
      tituloInicial: destino.nombre,
      descripcionInicial: destino.direccion,
    );
    if (!guardada || !mounted) return;
    setState(() => _guardada = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ruta guardada correctamente')),
    );
  }

  List<TripMetric> _metricas() {
    final ruta = _ruta;
    if (ruta == null) {
      return const [
        TripMetric(value: '--', unit: 'km', label: 'Distancia'),
        TripMetric(value: '--', unit: 'min', label: 'Duración'),
        TripMetric(value: '--:--', unit: '', label: 'Llegada'),
      ];
    }

    final (distancia, unidadDistancia) = ruta.distancia;
    final (tiempo, unidadTiempo) = ruta.tiempo;
    return [
      TripMetric(value: distancia, unit: unidadDistancia, label: 'Distancia'),
      TripMetric(value: tiempo, unit: unidadTiempo, label: 'Duración'),
      TripMetric(value: ruta.llegada, unit: '', label: 'Llegada'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final destino = widget.destino;
    final ruta = _ruta;
    final origen = _origen;

    return Scaffold(
      // app bar
      appBar: AppBar(
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,

        title: const Text('Viaje'),

        // franja con el recorrido
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),

          child: Container(
            width: double.infinity,
            color: colors.primary,

            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.md,
              vertical: AppPadding.sm,
            ),

            child: Text(
              'Ubicación actual > ${destino.nombre}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(color: colors.onPrimary),
            ),
          ),
        ),
      ),

      // contenido
      body: Stack(
        children: [
          // mapa con el recorrido
          Positioned.fill(
            child: MapaRuta(
              key: _mapaKey,
              destino: destino.posicion,
              origen: origen,
              puntos: ruta?.puntos ?? const [],
              tipo: _tipo,
              margenInferior: _altoCard,
            ),
          ),

          // herramientas + card de ruta
          Align(
            alignment: Alignment.bottomCenter,

            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.md),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: MapControls(
                        icons: _herramientas,
                        onPressed: (index) {
                          if (index == 0) {
                            setState(() {
                              _tipo = _tipo == MapType.normal
                                  ? MapType.terrain
                                  : MapType.normal;
                            });
                          } else {
                            _mapaKey.currentState?.ajustar();
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: AppGap.group),

                    RouteCard(
                      title: _error ??
                          (_cargando ? 'Calculando ruta…' : 'Ruta en bicicleta'),

                      metrics: _metricas(),

                      // con error, el botón principal vuelve a intentar
                      startLabel: _error != null ? 'Reintentar' : 'Iniciar',
                      onStart: _error != null
                          ? _cargar
                          : (ruta == null || origen == null)
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TripView(
                                    destino: destino,
                                    origen: origen,
                                    ruta: ruta,
                                  ),
                                ),
                              );
                            },

                      onClose: () => Navigator.pop(context),

                      // una ruta guardada ya está guardada
                      onSave: destino.esRuta || _guardada ? null : _guardar,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
