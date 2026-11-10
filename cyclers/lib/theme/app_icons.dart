import 'package:flutter/material.dart';

// ICONOGRAFÍA de Cyclers: los íconos con significado viven aquí, igual que
// colores y espaciados viven en theme.dart. Así se usan los mismos en el
// mapa, el panel, el buscador, las cards y los formularios.
//
// Regla:
//  - la FORMA dice qué es: lugar (pin), ruta (camino), recorrido (meta)
//  - el COLOR dice su estado: verde (primary) = guardado por ti,
//    gris (onSurfaceVariant) = de Google / sin guardar,
//    naranjo (tertiary) = tipo de bici
// Nunca solo el color: siempre cambia también la forma o hay texto.
class AppIcons {
  // qué es
  static const IconData lugar = Icons.place;
  static const IconData lugarSinGuardar = Icons.location_on_outlined;
  static const IconData ruta = Icons.route;
  static const IconData recorrido = Icons.sports_score;
  static const IconData todos = Icons.layers_outlined;

  // bici sin tipo elegido
  static const IconData bici = Icons.directions_bike;

  // acciones
  static const IconData buscar = Icons.search;
  static const IconData filtros = Icons.filter_alt_outlined;
  static const IconData fotos = Icons.photo_camera_outlined;
  static const IconData agregarFoto = Icons.add_a_photo_outlined;
  static const IconData editar = Icons.edit_outlined;
  static const IconData eliminar = Icons.delete_outline;
  static const IconData recientes = Icons.arrow_downward;
  static const IconData antiguas = Icons.arrow_upward;

  // ícono según el campo "tipo" de Firestore ('lugar' o 'ruta')
  static IconData deTipo(String? tipo) => tipo == 'ruta' ? ruta : lugar;
}

// tipos de bici (modo): nombre -> ícono.
// "Carretera" = bici de ruta; no se llama "Ruta" para no confundirla con
// las rutas guardadas.
const Map<String, IconData> kBicis = {
  'Urbana': Icons.directions_bike,
  'Montaña': Icons.terrain,
  'Carretera': Icons.add_road,
  'Eléctrica': Icons.electric_bike,
};

// dificultad -> barras, como la señal del celular (1, 2 o 3)
const Map<String, IconData> kIconosDificultad = {
  'Fácil': Icons.signal_cellular_alt_1_bar,
  'Media': Icons.signal_cellular_alt_2_bar,
  'Difícil': Icons.signal_cellular_alt,
};
