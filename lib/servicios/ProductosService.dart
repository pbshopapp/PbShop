import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ProductosService {
  final _supabase = Supabase.instance.client;

  Future<void> crearProductoAutomatico(
  BuildContext context, 
  String nombre, 
  double precio, // <--- CAMBIAR AQUÍ
  String descripcion, 
  List<XFile> imagenes) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inicia sesión para continuar")),
      );
      return;
    }

    try {
      // 1. Buscamos el perfil
      final perfil = await _supabase
          .from('perfiles')
          .select('fk_negocio')
          .eq('id', user.id)
          .single();

      final int? idNegocio = perfil['fk_negocio'];

      // --- MANEJO SI NO TIENE NEGOCIO ---
      if (idNegocio == null) {
        _mostrarDialogoSinPermiso(context);
        return;
      }

      // 2. Si tiene negocio, procedemos
      await _supabase.from('productos').insert({
        'nombre': nombre,
        'precio': precio,
        'fk_negocio': idNegocio,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Producto publicado con éxito!"), 
            backgroundColor: Colors.green
          ),
        );
      }

    } catch (e) {
      debugPrint("Error al crear producto: $e");
    }
  }

  void _mostrarDialogoSinPermiso(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Acceso Denegado"),
        content: const Text("Solo los perfiles de 'Vendedor' vinculados a un negocio pueden publicar productos."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Entendido"),
          ),
        ],
      ),
    );
  }
}