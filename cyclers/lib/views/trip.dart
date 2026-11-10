import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../services/places_service.dart';
import '../services/routes_service.dart';
import '../theme/app_icons.dart';
import '../theme/theme.dart';
import 'end_trip.dart';
import 'map_controls.dart';
import 'record_panel.dart';
import 'route_map.dart';
import 'trip_metrics.dart';
import 'turn_card.dart';

// pantalla "Ruta comenzada": el mismo mapa con el recorrido.
// Pausar -> "Ruta pausada" -> Terminar -> "¿Terminaste?" -> fin de recorrido.
class TripView extends StatefulWidget {
  const TripView({
    super.key,
    required this.destino,
    required this.origen,
    required this.ruta,
  });

  final Lugar destino;
  final LatLng origen;
  final RutaCalculada ruta;

  @override
  State<TripView> createState() => _TripViewState();
}

class _TripViewState extends State<TripView> {
  // alto aproximado del panel de abajo, para que la ruta no quede tapada
  static const double _altoPanel = 240;

  // relieve y ver todo el recorrido
  static const List<IconData> _herramientas = [
    Icons.terrain,
    Icons.zoom_out_map,
  ];

  // el Stopwatch mide el tiempo real. Cada segundo solo cambia _tiempo:
  // se redibuja el texto del reloj, no la pantalla entera (ni el mapa).
  final _reloj = Stopwatch()..start();
  final _tiempo = ValueNotifier<String>('00:00');
  Timer? _tic;
  bool _pausado = false;

  @override
  void initState() {
    super.initState();
    _tic = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_pausado) _tiempo.value = _formato();
    });
  }

  @override
  void dispose() {
    _tic?.cancel();
    _tiempo.dispose();
    super.dispose();
  }

  // "05:07" o "1:05:07"
  String _formato() {
    final total = _reloj.elapsed.inSeconds;
    String dos(int n) => n.toString().padLeft(2, '0');
    final horas = total ~/ 3600;
    final minutos = dos((total % 3600) ~/ 60);
    final segundos = dos(total % 60);
    return horas > 0 ? '$horas:$minutos:$segundos' : '$minutos:$segundos';
  }

  void _pausar() {
    _reloj.stop();
    setState(() => _pausado = true);
  }

  void _seguir() {
    _reloj.start();
    setState(() => _pausado = false);
  }

  Future<void> _terminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      // en web, evita que los toques del diálogo lleguen al mapa de abajo
      builder: (dialogContext) =>
          PointerInterceptor(child: const _DialogoTerminar()),
    );
    if (confirmar != true || !mounted) return;

    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EndTripView(
          destino: widget.destino,
          origen: widget.origen,
          ruta: widget.ruta,
          duracion: _reloj.elapsed,
        ),
      ),
    );
    if (guardado != true || !mounted) return;

    // vuelve al mapa de inicio y avisa
    final mensajes = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    mensajes.showSnackBar(
      const SnackBar(content: Text('Viaje finalizado y guardado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (restante, unidadRestante) = widget.ruta.distancia;

    return Scaffold(
      body: Stack(
        children: [
          // mapa con el recorrido
          Positioned.fill(
            child: MapaRuta(
              destino: widget.destino.posicion,
              origen: widget.origen,
              puntos: widget.ruta.puntos,
              margenInferior: _altoPanel,
            ),
          ),

          // arriba: hacia dónde vas, o la franja "Pausado"
          Align(
            alignment: Alignment.topCenter,

            child: _pausado
                ? const _FranjaPausado()
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppPadding.md),

                      child: PointerInterceptor(
                        child: TurnCard(
                          distance: 'Destino',
                          street: widget.destino.nombre,
                        ),
                      ),
                    ),
                  ),
          ),

          // herramientas + registro
          Align(
            alignment: Alignment.bottomCenter,

            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                Align(
                  alignment: Alignment.centerRight,

                  child: Padding(
                    padding: const EdgeInsets.all(AppPadding.md),

                    child: MapControls(
                      icons: _herramientas,
                      onPressed: (index) {},
                    ),
                  ),
                ),

                PointerInterceptor(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _tiempo,
                    builder: (context, tiempo, _) => RecordPanel(
                    time: tiempo,
                    paused: _pausado,

                    metrics: [
                      const TripMetric(
                        value: '0',
                        unit: 'km/h',
                        label: 'Velocidad',
                      ),
                      const TripMetric(
                        value: '0',
                        unit: 'mts',
                        label: 'Recorrido',
                      ),
                      TripMetric(
                        value: restante,
                        unit: unidadRestante,
                        label: 'Restante',
                      ),
                    ],

                    onPause: _pausar,
                    onResume: _seguir,
                    onFinish: _terminar,
                  ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// franja naranja de arriba (Figma: Ruta pausada)
class _FranjaPausado extends StatelessWidget {
  const _FranjaPausado();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      color: colors.tertiaryContainer,

      child: SafeArea(
        bottom: false,

        child: Padding(
          padding: const EdgeInsets.all(AppPadding.md),

          child: Text(
            'Pausado',
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(color: colors.tertiary),
          ),
        ),
      ),
    );
  }
}

// Figma: Dialog terminar ruta
class _DialogoTerminar extends StatelessWidget {
  const _DialogoTerminar();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        child: Icon(AppIcons.recorrido, color: colors.primary),
      ),
      title: const Text('¿Terminaste?'),
      // los botones van en content (y no en actions) para que midan lo mismo
      content: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          const Text(
            'El viaje se guardará en tu perfil y podrás ver el registro',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppGap.group),

          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Volver'),
                ),
              ),

              const SizedBox(width: AppGap.related),

              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sí, guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
