import 'package:supabase_flutter/supabase_flutter.dart';

class PedidoService {
  final _supabase = Supabase.instance.client;

  // Obtener el nombre del cliente por su ID
  Future<String> obtenerNombreCliente(String idUsuario) async {
    try {
      final data = await _supabase
          .from('perfiles')
          .select('nombre')
          .eq('id', idUsuario)
          .single();
      return data['nombre'] ?? "Usuario sin nombre";
    } catch (e) {
      return "Error al cargar nombre";
    }
  }

  // Obtener los productos detallados de un pedido
  Future<List<Map<String, dynamic>>> obtenerDetallesPedido(String idPedido) async {
    try {
      return await _supabase
          .from('detalles_pedido')
          .select('cantidad, precio_unitario, productos(nombre, imagen_url)')
          .eq('fk_pedido', idPedido);
    } catch (e) {
      return [];
    }
  }

  // Actualizar el estado de un pedido
  Future<bool> actualizarEstadoPedido(String idPedido, String nuevoEstado) async {
    try {
      await _supabase
          .from('pedidos')
          .update({'estado': nuevoEstado})
          .eq('id', idPedido);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Stream<Map<String, dynamic>?> getUltimoPedidoStream() {
  final userId = _supabase.auth.currentUser!.id;

  return _supabase
      .from('pedidos')
      .stream(primaryKey: ['id'])
      .eq('id_usuario', userId)
      .order('fecha', ascending: false)
      .limit(1)
      .map((list) => list.isNotEmpty ? list.first : null);
}
}