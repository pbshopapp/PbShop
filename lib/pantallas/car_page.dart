import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/servicios/CartService.dart';

class car_page extends StatefulWidget {
  const car_page({super.key});

  @override
  State<car_page> createState() => _car_pageState();
}

class _car_pageState extends State<car_page> {
  bool _isConfirming = false;
  final _cartService = CartService();
  int _pedidosActivos = 3; // Esto podrías consultarlo con un count en Supabase

  // --- FUNCIÓN RESTAURADA: CONFIRMAR PEDIDO ---
  Future<void> _confirmarPedido() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _cartService.items.isEmpty) {
      _mostrarMensaje("Inicia sesión para pedir", Colors.orange);
      return;
    }

    setState(() => _isConfirming = true);

    try {
      // 1. Insertar Cabecera (Tabla pedidos)
      final pedido = await Supabase.instance.client.from('pedidos').insert({
        'fk_usuario': user.id,
        'fk_negocio': _cartService.items.first.fkNegocio,
        'total': _cartService.granTotal,
        'estado': 'pendiente',
        'metodo_pago': 'Efectivo',
      }).select().single();

      // 2. Insertar Detalles (Tabla detalles_pedido)
      final detalles = _cartService.items.map((item) => {
        'fk_pedido': pedido['id'],
        'fk_producto': item.id,
        'cantidad': item.cantidad,
        'precio_unitario': item.precioUnitario,
      }).toList();

      await Supabase.instance.client.from('detalles_pedido').insert(detalles);

      // 3. Éxito: Limpiar y Notificar
      _cartService.limpiarCarrito();
      _mostrarMensaje("¡Pedido enviado con éxito!", Colors.green);
      
    } catch (e) {
      _mostrarMensaje("Error al procesar: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  void _mostrarMensaje(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Carrito"), centerTitle: true),
      body: ListenableBuilder(
        listenable: _cartService,
        builder: (context, _) {
          final items = _cartService.items;

          return Column(
            children: [
              // 1. PANEL SUPERIOR RESTAURADO (Estado y Ver Más)
              _buildPanelSuperiorRestaurado(),
              
              const Divider(height: 1),

              // 2. LISTA CENTRAL
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text("Tu carrito está vacío"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: items.length,
                        itemBuilder: (context, index) => _buildCardProducto(items[index], index),
                      ),
              ),

              // 3. PANEL DE TOTAL Y BOTÓN DE ACCIÓN
              _buildResumenTotal(items.isEmpty),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGETS RESTAURADOS ---

  Widget _buildPanelSuperiorRestaurado() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Estado del pedido más reciente", 
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const Text("👨‍🍳 En Preparación...", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromRGBO(0, 180, 195, 1))),
                if (_pedidosActivos > 2)
                  TextButton(
                    onPressed: () { /* Lógica para ver todos */ }, 
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                    child: const Text("Ver todos los pedidos actuales", style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          // Botón Historial restaurado
          IconButton.filledTonal(
            onPressed: () { /* Navegar al historial */ },
            icon: const Icon(Icons.history_rounded),
            tooltip: "Ver Historial",
          ),
        ],
      ),
    );
  }

  Widget _buildCardProducto(ItemCarrito item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("\$${item.precioUnitario} c/u", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 8),
                  Text("Total: \$${item.total}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
            // Controles de cantidad conectados al servicio profesional
            Row(
              children: [
                _btnQty(Icons.remove, () => _cartService.cambiarCantidad(index, false)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text("${item.cantidad}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                _btnQty(Icons.add, () => _cartService.cambiarCantidad(index, true)),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _cartService.eliminarProducto(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btnQty(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _buildResumenTotal(bool estaVacio) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total a pagar:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("\$${_cartService.granTotal}", 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color.fromRGBO(0, 180, 195, 1))),
            ],
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: (_isConfirming || estaVacio) ? null : _confirmarPedido,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: _isConfirming 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Confirmar Pedido", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}