import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/widgets/RaitingBar.dart';

class DetallePedidoDinamico extends StatelessWidget {
  final String idPedido;

  const DetallePedidoDinamico({super.key, required this.idPedido});

  // Color institucional
  final Color colorPB = const Color.fromRGBO(0, 180, 195, 1);

  Future<bool> _yaEstaCalificado({
    required String idPedido,
    String? idProducto,
  }) async {
    try {
      var query = Supabase.instance.client
          .from('resenas')
          .select()
          .eq('fk_pedido', idPedido);

      if (idProducto != null) {
        // Si mandamos producto, filtramos por ese producto
        query = query.eq('fk_producto', idProducto);
      } else {
        // Si NO mandamos producto, significa que estamos buscando la reseña del negocio
        query = query.isFilter('fk_producto', null);
      }

      final res = await query.maybeSingle();
      return res != null;
    } catch (e) {
      return false;
    }
  }
  @override
  Widget build(BuildContext context) {
    // Detectamos si el sistema está en modo oscuro
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Fondo adaptable
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text("ESTADO DEL PEDIDO",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: colorPB,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('pedidos')
            .stream(primaryKey: ['id'])
            .eq('id', idPedido),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colorPB));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No se encontró la información del pedido."));
          }

          final pedido = snapshot.data!.first;
          final String estadoActual = (pedido['estado'] ?? 'pendiente').toString().toLowerCase();

          return Column(
            children: [
              _buildHeaderStatus(pedido, isDarkMode),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildStepItem(
                        numero: "1",
                        titulo: "Pedido Recibido",
                        subtitulo: "Hemos recibido tu solicitud exitosamente.",
                        completado: true,
                        activo: estadoActual == 'pendiente',
                        esUltimo: false,
                        isDarkMode: isDarkMode,
                      ),
                      _buildStepItem(
                        numero: "2",
                        titulo: "En Preparación",
                        subtitulo: "El tendero está armando tu pedido.",
                        completado: _validar(estadoActual, 1),
                        activo: estadoActual == 'preparacion' || estadoActual == 'preparando',
                        esUltimo: false,
                        isDarkMode: isDarkMode,
                      ),
                      _buildStepItem(
                        numero: "3",
                        titulo: "Listo para Recogida",
                        subtitulo: "Ya puedes pasar por tus productos.",
                        completado: _validar(estadoActual, 2),
                        activo: estadoActual == 'listo',
                        esUltimo: false,
                        isDarkMode: isDarkMode,
                      ),
                      _buildStepItem(
                        numero: "4",
                        titulo: "Recogido",
                        subtitulo: "¡Disfruta tu compra!",
                        completado: estadoActual == 'entregado',
                        activo: estadoActual == 'entregado',
                        esUltimo: true,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 10),
                      _buildResumenCard(context, pedido, idPedido, isDarkMode),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _validar(String estado, int nivel) {
    final niveles = {
      'pendiente': 0,
      'preparacion': 1,
      'preparando': 1,
      'listo': 2,
      'entregado': 3,
      'cancelado': -1
    };
    return (niveles[estado] ?? 0) >= nivel;
  }

  Widget _buildHeaderStatus(Map<String, dynamic> pedido, bool isDarkMode) {
    final String estado = (pedido['estado'] ?? 'pendiente').toString().toLowerCase();
    bool esCancelado = estado == 'cancelado';
    String? motivo = pedido['motivo_cancelacion'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDarkMode) // Solo sombras en modo claro para evitar "brillo" extraño en dark
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: esCancelado ? Colors.red[50]?.withOpacity(isDarkMode ? 0.2 : 1) : colorPB.withOpacity(0.1),
            child: Icon(
              esCancelado ? Icons.close : Icons.check_circle_outline,
              color: esCancelado ? Colors.red : Colors.green,
              size: 40,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            esCancelado 
              ? "Pedido Cancelado" 
              : (estado == 'preparacion' || estado == 'preparando' 
                  ? "¡Estamos preparando tu pedido!" 
                  : "Estado: ${estado.toUpperCase()}"),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: esCancelado ? Colors.red[700] : (isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          if (esCancelado && motivo != null && motivo.isNotEmpty) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.red.withOpacity(0.1) : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                "Motivo: $motivo",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.red[200] : Colors.red[900], 
                  fontSize: 13, 
                  fontStyle: FontStyle.italic
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String numero,
    required String titulo,
    required String subtitulo,
    required bool completado,
    required bool activo,
    required bool esUltimo,
    required bool isDarkMode,
  }) {
    Color colorEje = completado ? Colors.green : (activo ? Colors.orange : (isDarkMode ? Colors.white24 : Colors.grey[300]!));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: colorEje, width: 2.5),
              ),
              child: Center(
                child: completado 
                  ? Icon(Icons.check, size: 16, color: colorEje)
                  : Text(numero, style: TextStyle(color: colorEje, fontWeight: FontWeight.bold)),
              ),
            ),
            if (!esUltimo) Container(width: 2, height: 50, color: colorEje.withOpacity(0.3)),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: activo ? (isDarkMode ? Colors.white : Colors.black) : (isDarkMode ? Colors.white54 : Colors.grey[700]))),
              Text(subtitulo, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumenCard(BuildContext context, Map<String, dynamic> pedido, String idPedido, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Resumen de compra", 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black
            )
          ),
          const Divider(height: 25),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _obtenerProductos(idPedido),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
              final detalles = snapshot.data ?? [];
              return Column(
                children: detalles.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${item['productos']['nombre']} x${item['cantidad']}", 
                        style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black87)),
                      Text("\$${(item['precio_unitario'] * item['cantidad'])}",
                        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black)),
                    ],
                  ),
                )).toList(),
              );
            },
          ),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total pagado:", style: TextStyle(color: Colors.grey)),
              Text("\$${pedido['total']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPB)),
            ],
          ),
          const SizedBox(height: 20),
          _buildAccionBoton(context, pedido, isDarkMode),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _obtenerProductos(String id) async {
    final res = await Supabase.instance.client
        .from('detalles_pedido')
        .select('*, productos(nombre)')
        .eq('fk_pedido', id);
    return List<Map<String, dynamic>>.from(res);
  }

  Widget _buildAccionBoton(BuildContext context, Map<String, dynamic> pedido, bool isDarkMode) {
    final bool esEntregado = pedido['estado']?.toString().toLowerCase() == 'entregado';

    if (esEntregado) {
      return FutureBuilder<bool>(
        future: _yaEstaCalificado(idPedido: pedido['id']),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return const Center(child: Text("⭐ Pedido calificado", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)));
          }
          return ElevatedButton.icon(
            onPressed: () => _mostrarDialogoResena(context, pedido['id'], isDarkMode),
            icon: const Icon(Icons.star_outline, color: Colors.white),
            label: const Text("CALIFICAR EXPERIENCIA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: colorPB, minimumSize: const Size(double.infinity, 45)),
          );
        },
      );
    }

    return OutlinedButton.icon(
      onPressed: () {}, // Lógica de chat
      icon: const Icon(Icons.chat_bubble_outline),
      label: const Text("Hablar con el vendedor"),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorPB, 
        minimumSize: const Size(double.infinity, 45),
        side: BorderSide(color: colorPB)
      ),
    );
  }

  void _mostrarDialogoResena(BuildContext context, String idPedido, bool isDarkMode) {
    int estrellas = 0;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("¿Qué tal estuvo todo?", 
          textAlign: TextAlign.center,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingBar(onRatingSelected: (val) => estrellas = val),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              maxLines: 2,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Escribe un comentario...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true, 
                fillColor: isDarkMode ? Colors.white10 : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: () async {
              if (estrellas == 0) return;
              final pedidoData = await Supabase.instance.client.from('pedidos').select('fk_negocio').eq('id', idPedido).single();
              await Supabase.instance.client.from('resenas').insert({
                'fk_pedido': idPedido,
                'puntuacion': estrellas,
                'comentario': controller.text.trim(),
                'fk_usuario': Supabase.instance.client.auth.currentUser!.id,
                'fk_negocio': pedidoData['fk_negocio'],
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorPB),
            child: const Text("ENVIAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}