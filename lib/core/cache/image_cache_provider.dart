// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter_media_metadata/flutter_media_metadata.dart';

// class ImageCacheProvider extends ChangeNotifier {
//   final Map<String, ImageProvider<Object>> _cache = {};

//   /// Obtiene una imagen desde cache o la carga si no existe
//   Future<ImageProvider<Object>> getImage(String key, {String? path}) async {
//     if (_cache.containsKey(key)) {
//       return _cache[key]!;
//     }

//     ImageProvider<Object> image;

//     if (path != null) {
//       final file = File(path);

//       // Intentamos leer metadatos para extraer carátula
//       try {
//         final metadataRetriever = MetadataRetriever();
//         final metadata = await MetadataRetriever.fromFile(file);

//         if (metadata.albumArt != null) {
//           image = MemoryImage(metadata.albumArt! as Uint8List);
//         } else {
//           // Si no hay carátula embebida, usamos el archivo como imagen directa
//           image = FileImage(file);
//         }
//       } catch (e) {
//         // Fallback en caso de error
//         image = FileImage(file);
//       }
//     } else {
//       // Fallback si no se pasa path
//       image = const AssetImage('assets/img/logo.png');
//     }

//     _cache[key] = image;
//     return image;
//   }

//   /// Permite limpiar el cache completo
//   void clearCache() {
//     _cache.clear();
//     notifyListeners();
//   }

//   /// Permite eliminar una imagen específica del cache
//   void removeImage(String key) {
//     _cache.remove(key);
//     notifyListeners();
//   }
// }
