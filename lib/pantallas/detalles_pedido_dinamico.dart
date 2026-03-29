import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetallePedidoDinamico extends StatelessWidget {
  final String idPedido;

  const DetallePedidoDinamico({super.key, required this.idPedido});

  
  @override
  Widget build(BuildContext context) {
    const colorTurquesa = Color.fromRGBO(0, 180, 195, 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text("ESTADO DEL PEDIDO",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: colorTurquesa,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('pedidos')
            .stream(primaryKey: ['id'])
            .eq('id', idPedido),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: colorTurquesa));
          }

          final pedido = snapshot.data!.first;
          final String estadoActual = pedido['estado'] ?? 'pendiente';

          return Column(
            children: [
              _buildHeaderStatus(estadoActual, colorTurquesa),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: ListView(
                    children: [
                      _buildStepItem(
                        numero: "1",
                        titulo: "Pedido Recibido",
                        subtitulo: "Hemos recibido tu solicitud exitosamente.",
                        completado: true,
                        activo: estadoActual == 'pendiente',
                        esUltimo: false,
                      ),
                      _buildStepItem(
                        numero: "2",
                        titulo: "En Preparación",
                        subtitulo: "El tendero está armando tu pedido.",
                        completado: _validar(estadoActual, 1),
                        activo: estadoActual == 'preparacion' || estadoActual == 'Preparando',
                        esUltimo: false,
                      ),
                      _buildStepItem(
                        numero: "3",
                        titulo: "Listo para Recogida",
                        subtitulo: "Te avisaremos cuando pases por él.",
                        completado: _validar(estadoActual, 2),
                        activo: estadoActual == 'Listo',
                        esUltimo: false,
                      ),
                      _buildStepItem(
                        numero: "4",
                        titulo: "Recogido",
                        subtitulo: "¡Disfruta tus productos!",
                        completado: estadoActual == 'entregado' || estadoActual == 'Entregado',
                        activo: estadoActual == 'entregado' || estadoActual == 'Entregado',
                        esUltimo: true,
                      ),
                      const SizedBox(height: 20),
                      // Pasamos el ID del pedido para buscar sus productos
                      _buildResumenCard(pedido, idPedido),
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
    final niveles = {'pendiente': 0, 'preparacion': 1, 'listo': 2, 'entregado': 3};
    String normalizado = estado.toLowerCase();
    return (niveles[normalizado] ?? 0) >= nivel;
  }

  Widget _buildHeaderStatus(String estado, Color color) {
    // Verificamos si el pedido fue cancelado
    bool esCancelado = estado.toLowerCase() == 'cancelado';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            // Cambia a fondo rojo suave si es cancelado, si no, azulito
            backgroundColor: esCancelado ? Colors.red[50] : const Color(0xFFE0F7F9),
            child: Icon(
              // El icono cambia a la 'X' roja o al 'chulo' verde
              esCancelado ? Icons.close : Icons.check_circle_outline,
              color: esCancelado ? Colors.red : Colors.green,
              size: 40,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            // Mensaje personalizado según el estado
            esCancelado 
              ? "Lo sentimos, tu pedido ha sido cancelado" 
              : (estado.toLowerCase() == 'preparacion' 
                  ? "¡Tu pedido está siendo preparado!" 
                  : "Estado: $estado"),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              // Si quieres que el texto también sea rojo cuando se cancele:
              color: esCancelado ? Colors.red[700] : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(
      {required String numero,
      required String titulo,
      required String subtitulo,
      required bool completado,
      required bool activo,
      required bool esUltimo}) {
    Color colorEje = completado ? Colors.green : (activo ? Colors.orange : Colors.grey[300]!);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: colorEje, width: 2.5),
              ),
              child: Center(
                child: Text(numero, style: TextStyle(color: colorEje, fontWeight: FontWeight.bold)),
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
                      fontSize: 16,
                      color: activo ? Colors.black : Colors.grey[700])),
              Text(subtitulo, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumenCard(Map<String, dynamic> pedido, String idPedido) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Resumen del Pedido",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 25),

          // --- LISTA DINÁMICA DE PRODUCTOS ---
          FutureBuilder<List<Map<String, dynamic>>>(
            future: Supabase.instance.client
                .from('detalles_pedido')
                .select('*, productos(nombre)') // Join con la tabla productos
                .eq('fk_pedido', idPedido),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text("No se encontraron productos para este pedido.");
              }

              final detalles = snapshot.data!;

              return Column(
                children: detalles.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${item['productos']['nombre']} x${item['cantidad']}",
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                        Text(
                          "\$${(item['precio_unitario'] * item['cantidad'])}",
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          // -----------------------------------

          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total:", style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text("\$${pedido['total']} COP",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(0, 180, 195, 1))),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.message),
              label: const Text("Enviar mensaje al tendero"),
              style: OutlinedButton.styleFrom(
                  foregroundColor: const Color.fromRGBO(0, 180, 195, 1)),
            ),
          )
        ],
      ),
    );
  }
}