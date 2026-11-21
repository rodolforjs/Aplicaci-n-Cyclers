import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/theme.dart';

// ─────────────────────────────────────────────
// INICIO: Explora (publicaciones de la comunidad) y Desafíos.
// Las publicaciones son de demostración: fotos de stock (Unsplash)
// y personas ficticias, solo para visualizar el diseño.
// ─────────────────────────────────────────────

String _foto(String id) =>
    'https://images.unsplash.com/photo-$id?w=900&q=70&auto=format&fit=crop';

class _Publicacion {
  const _Publicacion({
    required this.nombre,
    required this.accion,
    required this.dias,
    required this.lugar,
    required this.titulo,
    required this.texto,
    required this.foto,
    required this.km,
    required this.cimas,
    required this.reacciones,
  });

  final String nombre;
  final String accion;
  final int dias;
  final String lugar;
  final String titulo;
  final String texto;
  final String foto;
  final double km;
  final int cimas;
  final int reacciones;
}

const List<_Publicacion> _publicaciones = [
  _Publicacion(
    nombre: 'Alexis S.',
    accion: 'fue por un paseo',
    dias: 1,
    lugar: 'Lo Barnechea, Chile',
    titulo: 'Subida a Farellones',
    texto: 'Partimos temprano para evitar el calor. Las curvas finales no perdonan.',
    foto: '1534146789009-76ed5060ec70',
    km: 32.4,
    cimas: 1,
    reacciones: 12,
  ),
  _Publicacion(
    nombre: 'Camila R.',
    accion: 'terminó una ruta',
    dias: 2,
    lugar: 'Vitacura, Chile',
    titulo: 'Vuelta por el Bicentenario',
    texto: 'Ruta tranquila para empezar la semana. Ideal para ir con niños.',
    foto: '1541625602330-2277a4c46182',
    km: 9.8,
    cimas: 0,
    reacciones: 7,
  ),
  _Publicacion(
    nombre: 'Matías C.',
    accion: 'subió un cerro',
    dias: 3,
    lugar: 'Las Condes, Chile',
    titulo: 'Manquehue por el sendero',
    texto: 'Mucho polvo y piedra suelta, pero la vista de Santiago vale todo.',
    foto: '1633707167682-9068729bc84c',
    km: 14.2,
    cimas: 2,
    reacciones: 21,
  ),
  _Publicacion(
    nombre: 'Javiera P.',
    accion: 'fue por un paseo',
    dias: 5,
    lugar: 'Providencia, Chile',
    titulo: 'Ciclovía del Mapocho',
    texto: 'Del Costanera al centro sin auto. Pocas subidas y harta sombra.',
    foto: '1485965120184-e220f721d03e',
    km: 11.5,
    cimas: 0,
    reacciones: 9,
  ),
  _Publicacion(
    nombre: 'Diego F.',
    accion: 'terminó una ruta',
    dias: 7,
    lugar: 'San José de Maipo, Chile',
    titulo: 'Cajón del Maipo en grupo',
    texto: 'Salida del club. Próximo destino: El Morado.',
    foto: '1760462433816-e0957beeae27',
    km: 48.7,
    cimas: 3,
    reacciones: 34,
  ),
];

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

class InicioView extends StatelessWidget {
  const InicioView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: _Ancho(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppPadding.md,
                  AppPadding.md,
                  AppPadding.md,
                  AppPadding.sm,
                ),
                child: Text('Inicio', style: text.headlineSmall),
              ),
              TabBar(
                labelColor: colors.onSurface,
                unselectedLabelColor: colors.onSurfaceVariant,
                indicatorColor: colors.onSurface,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Explora'),
                  Tab(text: 'Desafíos'),
                ],
              ),
              const Expanded(
                child: TabBarView(children: [_Explora(), _Desafios()]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EXPLORA
// ─────────────────────────────────────────────
class _Explora extends StatelessWidget {
  const _Explora();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppPadding.md,
        AppPadding.md,
        AppPadding.md,
        AppSpacing.space1100,
      ),
      itemCount: _publicaciones.length,
      separatorBuilder: (context, i) => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppPadding.md),
        child: Divider(height: 1),
      ),
      itemBuilder: (context, i) => _TarjetaPublicacion(p: _publicaciones[i]),
    );
  }
}

class _TarjetaPublicacion extends StatefulWidget {
  const _TarjetaPublicacion({required this.p});

  final _Publicacion p;

  @override
  State<_TarjetaPublicacion> createState() => _TarjetaPublicacionState();
}

class _TarjetaPublicacionState extends State<_TarjetaPublicacion> {
  bool _siguiendo = false;
  bool _meGusta = false;

  void _proximamente() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Disponible pronto')));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final p = widget.p;
    final reacciones = p.reacciones + (_meGusta ? 1 : 0);
    final hace = p.dias == 1 ? 'Ayer' : 'Hace ${p.dias} días';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // autor + seguir
        Row(
          children: [
            CircleAvatar(
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: Text(p.nombre.substring(0, 1)),
            ),
            const SizedBox(width: AppGap.related),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${p.nombre} ${p.accion}', style: text.titleMedium),
                  Text('$hace · ${p.lugar}', style: text.bodyMedium),
                ],
              ),
            ),
            _siguiendo
                ? OutlinedButton(
                    onPressed: () => setState(() => _siguiendo = false),
                    child: const Text('Siguiendo'),
                  )
                : FilledButton(
                    onPressed: () => setState(() => _siguiendo = true),
                    child: const Text('Seguir'),
                  ),
          ],
        ),

        const SizedBox(height: AppGap.component),
        Text(p.titulo, style: text.titleLarge),
        const SizedBox(height: AppGap.tight),
        Text(p.texto, style: text.bodyLarge),
        const SizedBox(height: AppGap.component),

        // foto con datos encima
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  _foto(p.foto),
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  loadingBuilder: (context, child, progreso) => progreso == null
                      ? child
                      : ColoredBox(color: colors.surfaceContainer),
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: colors.surfaceContainer,
                    child: Icon(AppIcons.bici, color: colors.onSurfaceVariant),
                  ),
                ),
                Positioned(
                  left: AppPadding.sm,
                  top: AppPadding.sm,
                  child: Wrap(
                    spacing: AppGap.tight,
                    children: [
                      _Etiqueta(icono: AppIcons.ruta, texto: '${p.km} km'),
                      if (p.cimas > 0)
                        _Etiqueta(
                          icono: Icons.landscape_outlined,
                          texto: p.cimas == 1 ? '1 cima' : '${p.cimas} cimas',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppGap.related),
        Text('$reacciones personas reaccionaron', style: text.bodyMedium),

        // acciones
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              tooltip: 'Me gusta',
              onPressed: () => setState(() => _meGusta = !_meGusta),
              icon: Icon(
                _meGusta ? Icons.favorite : Icons.favorite_border,
                color: _meGusta ? colors.primary : null,
              ),
            ),
            IconButton(
              tooltip: 'Comentar',
              onPressed: _proximamente,
              icon: const Icon(Icons.chat_bubble_outline),
            ),
            IconButton(
              tooltip: 'Compartir',
              onPressed: _proximamente,
              icon: const Icon(Icons.ios_share),
            ),
          ],
        ),
      ],
    );
  }
}

// chip oscuro sobre la foto (km, cimas)
class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.sm,
          vertical: AppPadding.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: AppSpacing.space400, color: colors.onInverseSurface),
            const SizedBox(width: AppGap.tight),
            Text(
              texto,
              style: text.labelMedium?.copyWith(color: colors.onInverseSurface),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DESAFÍOS: el avance usa tus recorridos reales de Firestore
// ─────────────────────────────────────────────
class _Desafio {
  const _Desafio(this.titulo, this.detalle, this.icono, this.meta, this.unidad);

  final String titulo;
  final String detalle;
  final IconData icono;
  final double meta;
  final String unidad; // 'km' o 'viajes'
}

const List<_Desafio> _desafios = [
  _Desafio('50 km este mes', 'Suma kilómetros en tus viajes.', AppIcons.ruta, 50, 'km'),
  _Desafio('5 recorridos', 'Termina cinco viajes con Cyclers.', AppIcons.recorrido, 5, 'viajes'),
  _Desafio('Ruta de 100 km', 'Acumula 100 km pedaleando.', Icons.emoji_events_outlined, 100, 'km'),
];

class _Desafios extends StatelessWidget {
  const _Desafios();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('recorridos')
          .where('usuario', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        var km = 0.0;
        for (final doc in docs) {
          km += ((doc.data()['metros'] as num?)?.toDouble() ?? 0) / 1000;
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppPadding.md,
            AppPadding.md,
            AppPadding.md,
            AppSpacing.space1100,
          ),
          itemCount: _desafios.length,
          separatorBuilder: (context, i) => const SizedBox(height: AppGap.related),
          itemBuilder: (context, i) {
            final d = _desafios[i];
            final avance = d.unidad == 'km' ? km : docs.length.toDouble();
            return _TarjetaDesafio(desafio: d, avance: avance);
          },
        );
      },
    );
  }
}

class _TarjetaDesafio extends StatelessWidget {
  const _TarjetaDesafio({required this.desafio, required this.avance});

  final _Desafio desafio;
  final double avance;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final progreso = (avance / desafio.meta).clamp(0.0, 1.0);
    final listo = progreso >= 1;
    final valor = desafio.unidad == 'km'
        ? avance.toStringAsFixed(1)
        : avance.toStringAsFixed(0);
    final meta = desafio.meta.toStringAsFixed(0);

    return Material(
      color: colors.secondaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(desafio.icono, color: colors.onSecondaryContainer),
                const SizedBox(width: AppGap.related),
                Expanded(child: Text(desafio.titulo, style: text.titleMedium)),
                if (listo) Icon(Icons.check_circle, color: colors.primary),
              ],
            ),
            const SizedBox(height: AppGap.tight),
            Text(desafio.detalle, style: text.bodyMedium),
            const SizedBox(height: AppGap.component),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: AppSpacing.space200,
                color: colors.primary,
                backgroundColor: colors.surfaceContainerLowest,
              ),
            ),
            const SizedBox(height: AppGap.tight),
            Text('$valor de $meta ${desafio.unidad}', style: AppTypography.data3),
          ],
        ),
      ),
    );
  }
}
