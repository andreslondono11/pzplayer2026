import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// 🔧 Manejador universal de artwork para canciones, álbumes o artistas.
/// Usa `QueryArtworkWidget` para mostrar la imagen asociada al audio.
/// Si no hay imagen disponible, muestra un ícono musical por defecto.
class ArtworkHandler {
  /// Construye un widget de artwork adaptable.
  ///
  /// - [id]: ID del recurso (canción, álbum, artista).
  /// - [type]: Tipo de artwork (AUDIO, ALBUM, ARTIST).
  /// - [size]: Tamaño en píxeles del artwork.
  /// - [borderRadius]: Bordes redondeados opcionales.
  /// - [fit]: Ajuste de la imagen dentro del contenedor.
  static Widget buildUniversalArtwork({
    required int? id,
    required ArtworkType type,
    double size = 60,
    BorderRadius? borderRadius,
    BoxFit fit = BoxFit.cover,
  }) {
    // Si el ID es nulo o inválido, muestra un ícono musical genérico.
    if (id == null || id == 0) {
      return Icon(Icons.music_note, size: size * 0.8);
    }

    // Si el ID es válido, muestra el artwork usando QueryArtworkWidget.
    return QueryArtworkWidget(
      id: id,
      type: type,
      artworkFit: fit,
      artworkBorder: borderRadius ?? BorderRadius.circular(8),
      nullArtworkWidget: Icon(Icons.music_note, size: size * 0.8),
      size: size.toInt(),
    );
  }

  // En tu ArtworkHandler, cambia el buildFromSongId:
  static Widget buildFromSongPath({
    required String? path,
    double size = 60,
    BorderRadius? borderRadius,
  }) {
    if (path == null) return const Icon(Icons.music_note, size: 48);

    return QueryArtworkWidget(
      id: 0, // No necesitamos ID numérico si usamos la ruta
      type: ArtworkType.AUDIO,
      // 🔑 ESTA ES LA MAGIA: El widget buscará por la ruta del archivo
      nullArtworkWidget: const Icon(Icons.music_note, size: 48),
      artworkFit: BoxFit.cover,
      artworkBorder: borderRadius ?? BorderRadius.circular(8),
      size: size.toInt(),
    );
  }
}
