import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Para formatear fechas (agrega a pubspec.yaml)

class pedidos_neg_page extends StatefulWidget {
  const pedidos_neg_page({super.key});

  @override
  State<pedidos_neg_page> createState() => _PedidosNegocioPageState();
}

class _PedidosNegocioPageState extends State<pedidos_neg_page> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  String? _idNegocio;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _obtenerIdNegocio();
  }

  // Obtenemos el ID del negocio vinculado al perfil del usuario actual
  Future<void> _obtenerIdNegocio() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('perfiles')
          .select('fk_negocio')
          .eq('id', user.id)
          .single();

      setState(() {
        _idNegocio = data['fk_negocio'];
        _cargando = false;
      });
    } catch (e) {
      debugPrint("Error obteniendo negocio: $e");
      setState(() => _cargando = false);
    }
  }

  // Función para actualizar el estado del pedido en Supabase
  Future<void> _actualizarEstado(String pedidoId, String nuevoEstado) async {
    try {
      await _supabase
          .from('pedidos')
          .update({'estado': nuevoEstado})
          .eq('id', pedidoId);
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pedido actualizado a $nuevoEstado"))
        );
      }
    } catch (e) {
      debugPrint("Error actualizando estado: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_idNegocio == null) {
      return const Scaffold(body: Center(child: Text("No tienes un negocio vinculado a tu perfil.")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("PANEL DE TENDEROS"),
        backgroundColor: const Color.fromRGBO(0, 180, 195, 1), // Color turquesa de tu app
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.label,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: Colors.white
          ),
          tabs: const [
            Tab(text: "Pendientes"),
            Tab(text: "En Preparación"),
            Tab(text: "Listos"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListaPedidos("pendiente"),
          _buildListaPedidos("en_preparacion"),
          _buildListaPedidos("listo"),
        ],
      ),
    );
  }

  Widget _buildListaPedidos(String estadoFiltro) {
    // STREAM EN TIEMPO REAL: Escucha cambios en la tabla pedidos para el negocio actual
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('pedidos')
          .stream(primaryKey: ['id'])
          .eq('fk_negocio', _idNegocio!)
          .order('fecha', ascending: true), // Los más antiguos primero (urgentes)
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No hay pedidos en estado: $estadoFiltro"));
        }

        // Filtramos localmente por el estado de la pestaña
        final pedidos = snapshot.data!.where((p) => p['estado'] == estadoFiltro).toList();

        if (pedidos.isEmpty) {
          return Center(child: Text("No hay pedidos ${estadoFiltro.replaceAll('_', ' ')}"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: pedidos.length,
          itemBuilder: (context, index) {
            return _buildCardPedido(pedidos[index]);
          },
        );
      },
    );
  }

  Widget _buildCardPedido(Map<String, dynamic> pedido) {
    // Lógica para determinar si es urgente (ej. más de 15 min esperando)
    DateTime fechaPedido = DateTime.parse(pedido['fecha']);
    Duration diferencia = DateTime.now().difference(fechaPedido);
    bool esUrgent = diferencia.inMinutes > 15 && pedido['estado'] == 'pendiente';
    
    // Formatear la fecha/hora
    String horaFormateada = DateFormat('jm').format(fechaPedido.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          // Franja superior de urgencia
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: esUrgent ? Colors.red[400] : Colors.amber[400],
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(esUrgent ? "URGENTE" : "NORMAL", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("Hace ${diferencia.inMinutes} min ($horaFormateada)", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Pedido #${pedido['id'].toString().substring(0, 5)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("\$${(pedido['total'] as num).toInt()}", style: const TextStyle(fontSize: 18, color: Color.fromRGBO(0, 180, 195, 1), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 5),
                // Aquí podrías hacer otro FutureBuilder para obtener el nombre del cliente desde 'perfiles'
                const Text("Cliente: Ver Detalles", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                
                // Sección de iconos de artículos (Simulada, requiere query a detalles_pedido)
                Row(
                  children: [
                    const Icon(Icons.shopping_basket_outlined, color: Colors.grey),
                    const SizedBox(width: 10),
                    const Text("Iconos de productos...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(5)),
                      child: Text(pedido['metodo_pago'].toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                
                const SizedBox(height: 15),
                
                // BOTONES DE ACCIÓN DINÁMICOS
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildBotonAccionPrincipal(pedido),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Navegar a pantalla de detalles detallados
                          _mostrarDetallesPedido(pedido);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color.fromRGBO(0, 180, 195, 1)),
                          foregroundColor: const Color.fromRGBO(0, 180, 195, 1),
                        ),
                        child: const Text("Detalles"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Define qué botón mostrar según el estado actual
  Widget _buildBotonAccionPrincipal(Map<String, dynamic> pedido) {
    String estado = pedido['estado'];
    
    if (estado == "pendiente") {
      return ElevatedButton(
        onPressed: () => _actualizarEstado(pedido['id'], "en_preparacion"),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[600], foregroundColor: Colors.black),
        child: const Text("Empezar a Preparar"),
      );
    } else if (estado == "en_preparacion") {
      return ElevatedButton(
        onPressed: () => _actualizarEstado(pedido['id'], "listo"),
        style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(0, 180, 195, 1), foregroundColor: Colors.white),
        child: const Text("Marcar como Listo"),
      );
    } else {
      // Estado 'listo' u otros.
      return ElevatedButton(
        onPressed: null, // Deshabilitado o acción para entregar
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
        child: const Text("Listo para Recoger"),
      );
    }
  }

  // Ejemplo simple de cómo mostrar detalles (puedes crear una página nueva)
  void _mostrarDetallesPedido(Map<String, dynamic> pedido) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Detalles Pedido #${pedido['id'].toString().substring(0,5)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text("Notas: ${pedido['notas'] ?? 'Sin notas.'}"),
              const SizedBox(height: 20),
              const Text("Aquí cargarías los productos usando 'detalles_pedido'...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              // Aquí harías un FutureBuilder a 'detalles_pedido' uniendo con 'productos'
            ],
          ),
        );
      },
    );
  }
}