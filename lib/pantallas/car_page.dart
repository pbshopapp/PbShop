import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/servicios/CartService.dart';
import 'package:intl/intl.dart';


class car_page extends StatefulWidget {
  const car_page({super.key});

  @override
  State<car_page> createState() => _car_pageState();
}

class _car_pageState extends State<car_page> {
  bool _isConfirming = false;
  final _cartService = CartService();
  final f = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
  // Mapa para gestionar las notas de cada negocio de forma independiente
  final Map<String, TextEditingController> _notaControllers = {};

  @override
  void dispose() {
    // Limpieza de controladores para evitar fugas de memoria
    for (var controller in _notaControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  // --- FUNCIÓN ACTUALIZADA: CONFIRMAR PEDIDO POR TIENDA ---
  Future<void> _confirmarPedidoPorTienda(String idNegocio, List<ItemCarrito> itemsDeEsteNegocio) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _mostrarMensaje("Inicia sesión para pedir", Colors.orange);
      return;
    }

    setState(() => _isConfirming = true);

    try {
      // Calcular el total y obtener la nota específica de este negocio
      double totalNegocio = itemsDeEsteNegocio.fold(0, (sum, item) => sum + item.total);
      String notaTexto = _notaControllers[idNegocio]?.text ?? "";

      // 1. Insertar Cabecera en la tabla 'pedidos' incluyendo NOTAS
      final pedido = await Supabase.instance.client.from('pedidos').insert({
        'id_usuario': user.id,
        'fk_negocio': idNegocio,
        'total': totalNegocio,
        'estado': 'pendiente',
        'metodo_pago': 'efectivo',
        'notas': notaTexto, // <--- Integración de notas
      }).select().single();

      // 2. Preparar Detalles
      final detalles = itemsDeEsteNegocio.map((item) => {
        'fk_pedido': pedido['id'],
        'fk_producto': item.id,
        'cantidad': item.cantidad,
        'precio_unitario': item.precioUnitario,
      }).toList();

      // 3. Insertar Detalles en la tabla 'detalles_pedido'
      await Supabase.instance.client.from('detalles_pedido').insert(detalles);

      // 4. ÉXITO: Limpiar los productos de esta tienda directamente desde aquí
      setState(() {
        // Accedemos a la lista de items del servicio y removemos los del negocio actual
        _cartService.items.removeWhere((item) => item.fkNegocio == idNegocio);
      });

      // Limpiar el controlador de texto de la nota
      _notaControllers[idNegocio]?.clear();

      
      _mostrarMensaje("¡Pedido enviado a la tienda!", Colors.green);
      
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Mi Carrito"), centerTitle: true, elevation: 0),
      body: ListenableBuilder(
        listenable: _cartService,
        builder: (context, _) {
          final items = _cartService.items;

          if (items.isEmpty) {
            return const Center(child: Text("Tu carrito está vacío"));
          }

          // Agrupar los productos por negocio (fk_negocio)
          final Map<String, List<ItemCarrito>> gruposPorTienda = {};
          for (var item in items) {
            gruposPorTienda.putIfAbsent(item.fkNegocio, () => []).add(item);
          }

          return ListView(
            padding: const EdgeInsets.all(15),
            children: [
              // Generar una sección visual por cada tienda
              ...gruposPorTienda.entries.map((entry) => _buildSeccionTienda(entry.key, entry.value)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeccionTienda(String idNegocio, List<ItemCarrito> itemsTienda) {
    // Asegurar que exista un controlador para la nota de este negocio
    _notaControllers.putIfAbsent(idNegocio, () => TextEditingController());
    
    double subtotal = itemsTienda.fold(0, (sum, item) => sum + item.total);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // --- ENCABEZADO DINÁMICO CON NOMBRE DE TIENDA ---
          FutureBuilder<Map<String, dynamic>>(
            future: Supabase.instance.client
                .from('negocios')
                .select('nombre')
                .eq('id', idNegocio)
                .single(),
            builder: (context, snapshot) {
              String nombreTienda = "Cargando tienda...";
              if (snapshot.hasData) {
                nombreTienda = snapshot.data!['nombre'];
              }

              return Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront, color: Color.fromRGBO(0, 180, 195, 1)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        nombreTienda, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Lista de productos de esta tienda específica
          ...itemsTienda.map((item) {
            int originalIndex = _cartService.items.indexOf(item);
            return _buildCardProducto(item, originalIndex);
          }),

          // Campo de Notas para el pedido
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: TextField(
              controller: _notaControllers[idNegocio],
              maxLines: 1,
              decoration: InputDecoration(
                hintText: "Notas para esta tienda (opcional)",
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Resumen y Botón de Pago de la tienda
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Subtotal tienda", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(f.format(subtotal), 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                ElevatedButton(
                  onPressed: _isConfirming ? null : () => _confirmarPedidoPorTienda(idNegocio, itemsTienda),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isConfirming 
                    ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Confirmar Pedido"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGETS RESTAURADOS ---

  Widget _buildCardProducto(ItemCarrito item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text("${f.format(item.precioUnitario)} c/u", 
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              _btnQty(Icons.remove, () => _cartService.cambiarCantidad(index, false)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text("${item.cantidad}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              _btnQty(Icons.add, () => _cartService.cambiarCantidad(index, true)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            onPressed: () => _cartService.eliminarProducto(index),
          ),
        ],
      ),
    );
  }

  Widget _btnQty(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16),
      ),
    );
  }
}