import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../theme/app_icons.dart';
import '../theme/theme.dart';
import 'trip_metrics.dart';

// calificación guardada en end_trip (1, 2 o 3)
const List<String> _calificaciones = ['Mal', 'Normal', 'Bien'];

// recorridos del usuario: los que se guardan al terminar un viaje
Stream<QuerySnapshot<Map<String, dynamic>>> _misRecorridos() {
  return FirebaseFirestore.instance
      .collection('recorridos')
      .where('usuario', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
      .snapshots();
}

// más recientes primero (se ordena aquí para no necesitar índice en Firestore)
List<QueryDocumentSnapshot<Map<String, dynamic>>> _ordenar(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  final lista = [...docs];
  lista.sort((a, b) {
    final fa = a.data()['creadoEn'] as Timestamp?;
    final fb = b.data()['creadoEn'] as Timestamp?;
    return (fb?.millisecondsSinceEpoch ?? 0).compareTo(
      fa?.millisecondsSinceEpoch ?? 0,
    );
  });
  return lista;
}

// en computador el contenido queda centrado y con ancho de celular
class _Ancho extends StatelessWidget {
  const _Ancho({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: child,
      ),
    );
  }
}

String _km(num metros) => (metros / 1000).toStringAsFixed(1);

String _duracion(int segundos) {
  final d = Duration(seconds: segundos);
  if (d.inHours > 0) return '${d.inHours} h ${d.inMinutes.remainder(60)} min';
  return '${d.inMinutes} min';
}

String _fecha(Timestamp? creado) {
  if (creado == null) return '';
  const meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
    'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];
  final f = creado.toDate();
  return '${f.day} de ${meses[f.month - 1]}, ${f.year}';
}

// ─────────────────────────────────────────────
// PERFIL: datos de la cuenta + resumen de actividad
// ─────────────────────────────────────────────
class PerfilView extends StatelessWidget {
  const PerfilView({super.key});

  Future<void> _cerrarSesion() async {
    if (!kIsWeb) await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final usuario = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: _Ancho(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppPadding.md,
          AppPadding.md,
          AppPadding.md,
          AppSpacing.space1100,
        ),
        children: [
          // cerrar sesión arriba a la derecha
          Align(
            alignment: Alignment.centerRight,
            child: IconButton.outlined(
              tooltip: 'Cerrar sesión',
              onPressed: _cerrarSesion,
              icon: const Icon(Icons.logout),
            ),
          ),

          // foto y nombre de la cuenta de Google
          Row(
            children: [
              _Avatar(url: usuario?.photoURL),
              const SizedBox(width: AppGap.component),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario?.displayName ?? 'Ciclista',
                      style: text.headlineSmall,
                    ),
                    if (usuario?.email != null)
                      Text(usuario!.email!, style: text.bodyMedium),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppGap.section),
          Text('Mi actividad', style: text.titleLarge),
          const SizedBox(height: AppGap.component),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _misRecorridos(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? const [];
              var metros = 0.0;
              var segundos = 0;
              for (final doc in docs) {
                metros += (doc.data()['metros'] as num?)?.toDouble() ?? 0;
                segundos += (doc.data()['segundos'] as num?)?.toInt() ?? 0;
              }

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppGap.related,
                crossAxisSpacing: AppGap.related,
                childAspectRatio: 1.6,
                children: [
                  _Dato(
                    valor: '${docs.length}',
                    etiqueta: 'Recorridos hechos',
                    icono: AppIcons.recorrido,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecorridosView(),
                      ),
                    ),
                  ),
                  _Dato(
                    valor: _km(metros),
                    etiqueta: 'Kilómetros',
                    icono: AppIcons.ruta,
                  ),
                  _Dato(
                    valor: _duracion(segundos),
                    etiqueta: 'Tiempo pedaleando',
                    icono: Icons.timer_outlined,
                  ),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('rutas')
                        .snapshots(),
                    builder: (context, rutas) => _Dato(
                      valor: '${rutas.data?.docs.length ?? 0}',
                      etiqueta: 'Guardados',
                      icono: AppIcons.lugar,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const double lado = AppSpacing.space1200;

    return ClipOval(
      child: SizedBox(
        width: lado,
        height: lado,
        child: url == null
            ? ColoredBox(
                color: colors.primaryContainer,
                child: Icon(Icons.person, color: colors.onPrimaryContainer),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: colors.primaryContainer,
                  child: Icon(Icons.person, color: colors.onPrimaryContainer),
                ),
              ),
      ),
    );
  }
}

// tarjeta de resumen: número grande + etiqueta + ícono (como en el Figma)
class _Dato extends StatelessWidget {
  const _Dato({
    required this.valor,
    required this.etiqueta,
    required this.icono,
    this.onTap,
  });

  final String valor;
  final String etiqueta;
  final IconData icono;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.secondaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(child: Text(valor, style: AppTypography.data2)),
                  Icon(icono, color: colors.onSecondaryContainer),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      etiqueta,
                      style: text.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LISTA de recorridos hechos
// ─────────────────────────────────────────────
class RecorridosView extends StatelessWidget {
  const RecorridosView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Recorridos hechos')),
      body: _Ancho(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _misRecorridos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar tus recorridos.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = _ordenar(snapshot.data!.docs);
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.lg),
                child: Text(
                  'Todavía no terminas ningún viaje. Cuando lo hagas, aparecerá aquí.',
                  style: text.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppPadding.md),
            itemCount: docs.length,
            separatorBuilder: (context, i) => const Divider(),
            itemBuilder: (context, i) => _FilaRecorrido(doc: docs[i]),
          );
        },
      ),
      ),
    );
  }
}

class _FilaRecorrido extends StatelessWidget {
  const _FilaRecorrido({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = doc.data();
    final fotos = (r['fotos'] as List?)?.cast<String>() ?? const [];
    final detalle = [
      _duracion((r['segundos'] as num?)?.toInt() ?? 0),
      '${_km(r['metros'] as num? ?? 0)} km',
      if (r['bici'] != null) r['bici'] as String,
    ].join(' · ');

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecorridoDetalleView(datos: r),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppPadding.sm),
        child: Row(
          children: [
            _Miniatura(url: fotos.isEmpty ? null : fotos.first),
            const SizedBox(width: AppGap.component),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['titulo'] as String? ?? 'Recorrido',
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppGap.tight),
                  Text(detalle, style: text.bodyMedium),
                  Text(
                    _fecha(r['creadoEn'] as Timestamp?),
                    style: text.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

// foto del recorrido o, si no tiene, el ícono de recorrido
class _Miniatura extends StatelessWidget {
  const _Miniatura({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const double lado = AppSpacing.space1100;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        width: lado,
        height: lado,
        child: url == null
            ? ColoredBox(
                color: colors.primaryContainer,
                child: Icon(
                  AppIcons.recorrido,
                  color: colors.onPrimaryContainer,
                ),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DETALLE de un recorrido (solo lectura)
// ─────────────────────────────────────────────
class RecorridoDetalleView extends StatelessWidget {
  const RecorridoDetalleView({super.key, required this.datos});

  final Map<String, dynamic> datos;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fotos = (datos['fotos'] as List?)?.cast<String>() ?? const [];
    final metros = datos['metros'] as num? ?? 0;
    final segundos = (datos['segundos'] as num?)?.toInt() ?? 0;
    // con menos de un minuto el promedio no dice nada (viajes de prueba)
    final kmh = segundos >= 60 ? (metros / 1000) / (segundos / 3600) : null;
    final destino = (datos['destino'] as Map?)?['nombre'] as String?;
    final calificacion = datos['calificacion'] as int?;
    final comentario = datos['comentario'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Recorrido')),
      body: _Ancho(
        child: ListView(
        padding: const EdgeInsets.all(AppPadding.md),
        children: [
          Text(
            datos['titulo'] as String? ?? 'Recorrido',
            style: text.headlineSmall,
          ),
          const SizedBox(height: AppGap.tight),
          Text(
            [
              if (destino != null) 'Hacia $destino',
              _fecha(datos['creadoEn'] as Timestamp?),
            ].join(' · '),
            style: text.bodyMedium,
          ),

          const SizedBox(height: AppGap.group),
          TripMetrics(
            title: 'Registro',
            metrics: [
              TripMetric(value: _km(metros), unit: 'km', label: 'Distancia'),
              TripMetric(
                value: _duracion(segundos),
                unit: '',
                label: 'Tiempo',
              ),
              TripMetric(
                value: kmh?.toStringAsFixed(1) ?? '—',
                unit: 'km/h',
                label: 'Promedio',
              ),
            ],
          ),

          if (fotos.isNotEmpty) ...[
            const SizedBox(height: AppGap.group),
            SizedBox(
              height: AppSpacing.space1200 * 2,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: fotos.length,
                separatorBuilder: (context, i) =>
                    const SizedBox(width: AppGap.related),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      fotos[i],
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppGap.group),
          Wrap(
            spacing: AppGap.related,
            runSpacing: AppGap.related,
            children: [
              if (datos['bici'] != null)
                Chip(
                  avatar: Icon(kBicis[datos['bici']] ?? AppIcons.bici),
                  label: Text(datos['bici'] as String),
                ),
              if (calificacion != null &&
                  calificacion >= 1 &&
                  calificacion <= _calificaciones.length)
                Chip(label: Text(_calificaciones[calificacion - 1])),
            ],
          ),

          if (comentario.isNotEmpty) ...[
            const SizedBox(height: AppGap.component),
            Text(comentario, style: text.bodyLarge),
          ],
        ],
      ),
      ),
    );
  }
}
