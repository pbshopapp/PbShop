import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ProductosService {
  final _supabase = Supabase.instance.client;

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

      // 3. Subir imágenes con la estructura: negocio_id / producto_id / imagen_N
      List<Map<String, dynamic>> registrosImagenes = [];

      for (int i = 0; i < imagenes.length; i++) {
        final img = imagenes[i];
        final bytes = await img.readAsBytes();
        final extension = img.path.split('.').last.toLowerCase();
        
        // ESTRUCTURA: Carpeta_Negocio / Carpeta_Producto / imagen_N.ext
        // Usamos el ID del producto para que la carpeta sea única y no haya choques de nombres
        final String pathFinal = '$fkNegocio/$productoId/imagen_${i + 1}.$extension';

        await _supabase.storage.from('productos').uploadBinary(
          pathFinal,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$extension',
            upsert: true, // Si por algún motivo ya existe, lo sobrescribe
          ),
        );

        // Obtener la URL pública de la imagen recién subida
        final url = _supabase.storage.from('productos').getPublicUrl(pathFinal);
        
        registrosImagenes.add({
          'fk_producto': productoId,
          'url': url,
        });
      }

      // 4. Guardar las URLs en la tabla secundaria y actualizar la principal
      if (registrosImagenes.isNotEmpty) {
        // Insertar todas las imágenes en 'imagenes_producto'
        await _supabase.from('imagenes_producto').insert(registrosImagenes);
        
        // Establecer la primera imagen como la principal del producto
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