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
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'Sesión expirada';

      // 1. Obtener datos del negocio
      final perfil = await _supabase
          .from('perfiles')
          .select('fk_negocio')
          .eq('id', user.id)
          .single();

      final String? fkNegocio = perfil['fk_negocio'];
      if (fkNegocio == null) throw 'No tienes un negocio vinculado';

      // 2. Insertar PRIMERO el producto para obtener su ID
      // Usamos .select().single() para que nos devuelva la fila recién creada
      final nuevoProducto = await _supabase.from('productos').insert({
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'fk_negocio': fkNegocio,
        'disponible': true,
        // Opcional: dejamos imagen_url con la primera foto como 'portada'
      }).select().single();

      final String productoId = nuevoProducto['id'];

      // 3. Preparar carpetas y subir imágenes
      final String nombreProductoFolder = nombre
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '_');

      List<Map<String, dynamic>> registrosImagenes = [];

      for (var img in imagenes) {
        final bytes = await img.readAsBytes();
        final extension = img.path.split('.').last.toLowerCase();
        
        // Estructura: negocio_id / nombre_producto / timestamp.ext
        final fileName = '$fkNegocio/$nombreProductoFolder/${DateTime.now().millisecondsSinceEpoch}.$extension';

        await _supabase.storage.from('productos').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$extension'),
        );

        final url = _supabase.storage.from('productos').getPublicUrl(fileName);
        
        // Guardamos la relación: ID del producto y su URL
        registrosImagenes.add({
          'fk_producto': productoId,
          'url': url,
        });
      }

      // 4. Insertar todas las URLs en la nueva entidad 'imagenes_producto'
      if (registrosImagenes.isNotEmpty) {
        await _supabase.from('imagenes_producto').insert(registrosImagenes);
        
        // OPCIONAL: Actualizar la 'imagen_url' principal del producto con la primera foto
        await _supabase.from('productos')
            .update({'imagen_url': registrosImagenes.first['url']})
            .eq('id', productoId);
      }

    } catch (e) {
      debugPrint("Error catastrófico: $e");
      rethrow;
    }
  }
}