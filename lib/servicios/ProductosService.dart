import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

class ProductosService {
  final _supabase = Supabase.instance.client;

  Future<void> actualizarProducto({
    required String id,
    required String nombre,
    required double precio,
    required String descripcion,
    required String categoria,
  }) async {
    await _supabase.from('productos').update({
      'nombre': nombre,
      'precio': precio,
      'descripcion': descripcion,
      'fk_categoria': categoria,
    }).eq('id', id);
  }

  Future<void> eliminarImagenCompleto(String imagenId, String url) async {
    try {
      // 1. Extraer el path relativo para el Storage
      // La URL suele ser: .../storage/v1/object/public/productos/negocioID/productoID/imagen.jpg
      // Necesitamos solo: negocioID/productoID/imagen.jpg
      final Uri uri = Uri.parse(url);
      final String pathEnStorage = uri.path.split('public/productos/').last;

      // 2. Eliminar el archivo físico del Storage
      final List<FileObject> response = await _supabase
          .storage
          .from('productos')
          .remove([pathEnStorage]);

      if (response.isEmpty) {
        debugPrint("Advertencia: No se encontró el archivo físico en el Storage");
      }

      // 3. Eliminar el registro de la tabla imagenes_producto
      await _supabase
          .from('imagenes_producto')
          .delete()
          .eq('id', imagenId);

      debugPrint("Imagen eliminada con éxito: $imagenId");
    } catch (e) {
      debugPrint("Error crítico al eliminar imagen: $e");
      rethrow;
    }
  }

  Future<void> subirFotosAdicionales(String productoId, String fkNegocio, List<XFile> nuevasImagenes) async {
    List<Map<String, dynamic>> registrosNuevos = [];

    for (int i = 0; i < nuevasImagenes.length; i++) {
      final img = nuevasImagenes[i];
      final bytes = await img.readAsBytes();
      final String mimeType = img.mimeType ?? 'image/jpeg';
      final String extension = mimeType.split('/').last;

      // Nombre único usando timestamp para no sobrescribir las existentes
      final String pathFinal = '$fkNegocio/$productoId/extra_${DateTime.now().millisecondsSinceEpoch}_$i.$extension';

      await _supabase.storage.from('productos').uploadBinary(
        pathFinal,
        bytes,
        fileOptions: FileOptions(contentType: mimeType, upsert: true),
      );

      final url = _supabase.storage.from('productos').getPublicUrl(pathFinal);
      registrosNuevos.add({'fk_producto': productoId, 'url': url});
    }

    if (registrosNuevos.isNotEmpty) {
      await _supabase.from('imagenes_producto').insert(registrosNuevos);
    }
  }
  Future<void> crearProductoAutomatico(
    BuildContext context,
    String nombre,
    double precio,
    String descripcion,
    List<XFile> imagenes,
    String fkCategoria,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'Sesión expirada';

      // 1. Obtener ID del negocio del perfil del usuario
      final perfil = await _supabase
          .from('perfiles')
          .select('fk_negocio')
          .eq('id', user.id)
          .maybeSingle();

      if (perfil == null || perfil['fk_negocio'] == null) {
        throw 'No tienes un negocio vinculado para publicar productos';
      }

      final String fkNegocio = perfil['fk_negocio'].toString();

      // 2. Insertar el producto para obtener su ID único (UUID)
      final nuevoProducto = await _supabase.from('productos').insert({
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'fk_negocio': fkNegocio,
        'fk_categoria': fkCategoria,
        'disponible': true,
      }).select().single();

      final String productoId = nuevoProducto['id'].toString();

      // 3. Subir imágenes
      List<Map<String, dynamic>> registrosImagenes = [];

      for (int i = 0; i < imagenes.length; i++) {
        final img = imagenes[i];
        
        // CAMBIO CRÍTICO: Leer bytes primero
        final Uint8List bytes = await img.readAsBytes();
        
        // CAMBIO CRÍTICO: En Web, img.path no tiene extensión confiable. 
        // Usamos mimeType o por defecto 'jpeg'
        final String mimeType = img.mimeType ?? 'image/jpeg';
        final String extension = mimeType.split('/').last;
        
        // ESTRUCTURA: Carpeta_Negocio / Carpeta_Producto / imagen_N.ext
        final String pathFinal = '$fkNegocio/$productoId/imagen_${i + 1}.$extension';

        // CAMBIO CRÍTICO: Asegurar el Content-Type correcto en el upload
        await _supabase.storage.from('productos').uploadBinary(
          pathFinal,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType, // Usar el mimeType detectado
            upsert: true,
          ),
        );

        final url = _supabase.storage.from('productos').getPublicUrl(pathFinal);
        
        registrosImagenes.add({
          'fk_producto': productoId,
          'url': url,
        });
      }

      // 4. Guardar las URLs
      if (registrosImagenes.isNotEmpty) {
        await _supabase.from('imagenes_producto').insert(registrosImagenes);
        
        await _supabase.from('productos')
            .update({'imagen_url': registrosImagenes.first['url']})
            .eq('id', productoId);
      }

    } catch (e) {
      debugPrint("Error en ProductosService: $e");
      rethrow;
    }
  }
}