import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/pantallas/detalles_pedido_dinamico.dart';

class MisPedidosPage extends StatefulWidget {
  const MisPedidosPage({super.key});

  @override
  State<MisPedidosPage> createState() => _MisPedidosPageState();
}

class _MisPedidosPageState extends State<MisPedidosPage> {
  bool _mostrarTodoElHistorial = false;
  final colorTurquesa = const Color.fromRGBO(0, 180, 195, 1);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Fondo dinámico según el tema
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text("MIS PEDIDOS", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
        centerTitle: true,
        backgroundColor: colorTurquesa,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('pedidos')
            .stream(primaryKey: ['id'])
            .eq('id_usuario', supabase.auth.currentUser!.id.trim())
            .order('fecha', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("No tienes pedidos registrados", 
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
            );
          }

          final todosLosPedidos = snapshot.data!;
          
          final activos = todosLosPedidos.where((p) {
            final est = p['estado']?.toString().toLowerCase();
            return est != 'entregado' && est != 'cancelado';
          }).toList();

          final historial = todosLosPedidos.where((p) {
            final est = p['estado']?.toString().toLowerCase();
            return est == 'entregado' || est == 'cancelado';
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activos.isNotEmpty) ...[
                _EtiquetaSeccion(texto: "PEDIDOS ACTIVOS", isDark: isDark),
                ...activos.map((p) => _TarjetaPedidoCalcada(pedido: p, esActivo: true, isDark: isDark)),
                const SizedBox(height: 25),
              ],

              if (historial.isNotEmpty) ...[
                _EtiquetaSeccion(texto: "HISTORIAL", isDark: isDark),
                ...historial
                    .take(_mostrarTodoElHistorial ? historial.length : 3)
                    .map((p) => _TarjetaPedidoCalcada(pedido: p, esActivo: false, isDark: isDark)),

                if (historial.length > 3)
                  Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _mostrarTodoElHistorial = !_mostrarTodoElHistorial),
                      icon: Icon(_mostrarTodoElHistorial ? Icons.keyboard_arrow_up : Icons.history, size: 18),
                      label: Text(_mostrarTodoElHistorial ? "Ver menos" : "Ver todo el historial"),
                      style: TextButton.styleFrom(
                        foregroundColor: colorTurquesa, 
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EtiquetaSeccion extends StatelessWidget {
  final String texto;
  final bool isDark;
  const _EtiquetaSeccion({required this.texto, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(texto, 
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: isDark ? Colors.white38 : Colors.blueGrey, 
          letterSpacing: 1.1
        )
      ),
    );
  }
}

class _TarjetaPedidoCalcada extends StatelessWidget {
  final Map<String, dynamic> pedido;
  final bool esActivo;
  final bool isDark;

  const _TarjetaPedidoCalcada({required this.pedido, required this.esActivo, required this.isDark});

  Color _obtenerColorPorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'cancelado': return isDark ? Colors.redAccent.shade100 : Colors.red;
      case 'pendiente': return Colors.orange;
      case 'preparando': 
      case 'preparacion': return isDark ? Colors.blueAccent.shade100 : Colors.blue;
      case 'listo': return isDark ? Colors.greenAccent.shade200 : Colors.green;
      case 'entregado': return isDark ? Colors.white38 : Colors.grey;
      default: return isDark ? Colors.white54 : Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = pedido['estado']?.toString() ?? 'Pendiente';
    final esCancelado = estado.toLowerCase() == 'cancelado';
    final colorEstado = _obtenerColorPorEstado(estado);
    const colorTurquesa = Color.fromRGBO(0, 180, 195, 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          if (!isDark) 
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetallePedidoDinamico(idPedido: pedido['id'].toString())),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorEstado.withOpacity(0.1), 
                    shape: BoxShape.circle
                  ),
                  child: Icon(
                    esCancelado 
                        ? Icons.close 
                        : (esActivo ? Icons.shopping_bag : Icons.check_circle), 
                    color: colorEstado, 
                    size: 26
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pedido #${pedido['id'].toString().substring(0, 5)}", 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87
                        )
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorEstado.withOpacity(0.15), 
                          borderRadius: BorderRadius.circular(20)
                        ),
                        child: Text(
                          estado.toUpperCase(), 
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorEstado)
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "\$${pedido['total']} COP", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorTurquesa)
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.white24 : Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}