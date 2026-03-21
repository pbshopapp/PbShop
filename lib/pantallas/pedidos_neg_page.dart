import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pbshop/servicios/PedidoService.dart';

class pedidos_neg_page extends StatefulWidget {
  const pedidos_neg_page({super.key});

  @override
  State<pedidos_neg_page> createState() => _PedidosNegocioPageState();
}

class _PedidosNegocioPageState extends State<pedidos_neg_page> with SingleTickerProviderStateMixin {
  bool _estaBuscando = false;
  final TextEditingController _searchController = TextEditingController();
  String _textoBusqueda = "";
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  final _pedidoService = PedidoService();

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
    // Agregamos .select() al final para que nos devuelva la fila actualizada
    final data = await _supabase
        .from('pedidos')
        .update({'estado': nuevoEstado})
        .eq('id', pedidoId)
        .select(); // <--- IMPORTANTE

    if (data.isEmpty) {
      // Si data está vacío, significa que el RLS bloqueó el update o el ID no existe
      _mostrarMensaje("Error: No tienes permisos para actualizar este pedido", Colors.orange);
    } else {
      _mostrarMensaje("Pedido actualizado a $nuevoEstado", Colors.green);
      if (mounted) {
      setState(() {
        // No necesitas cambiar ninguna variable, solo disparar el redibujado
      });
      
      _mostrarMensaje("Pedido movido a $nuevoEstado", Colors.green);
    }
    }
  } catch (e) {
    _mostrarMensaje("Error de conexión: $e", Colors.red);
  }
}

  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  if (_cargando) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  return Scaffold(
    backgroundColor: Colors.grey[100], // Fondo gris claro para que las tarjetas blancas resalten
      appBar: AppBar(
        title: _estaBuscando 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Buscar pedido o cliente...",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onChanged: (val) {
                setState(() => _textoBusqueda = val.toLowerCase());
              },
            )
          : const Text("PEDIDOS PENDIENTES", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_estaBuscando ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _estaBuscando = !_estaBuscando;
                if (!_estaBuscando) {
                  _searchController.clear();
                  _textoBusqueda = "";
                }
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
            child: Container(
              height: 45,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color.fromRGBO(0, 180, 195, 1),
                unselectedLabelColor: Colors.white,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                tabs: const [
                  Tab(text: "Pendientes"),
                  Tab(text: "En Proceso"),
                  Tab(text: "Listos"),
                ],
              ),
            ),
          ),
        ),
      ),
      // El TabBarView debe tener el mismo controlador que el TabBar
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(), // Da ese efecto elástico de iOS al llegar al final
        children: [
          _buildListaPedidos("pendiente"),
          _buildListaPedidos("preparacion"),
          _buildListaPedidos("listo"),
        ],
      ),
    );
  }

  Widget _buildListaPedidos(String estadoFiltro) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('pedidos')
          .stream(primaryKey: ['id'])
          .eq('fk_negocio', _idNegocio!)
          .order('fecha', ascending: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEstadoVacio("No hay pedidos");
        }

        // FILTRO MULTIPLE: Por estado Y por texto de búsqueda
        final pedidosFiltrados = snapshot.data!.where((pedido) {
          final coincideEstado = pedido['estado'].toString().toLowerCase() == estadoFiltro;
          
          // Si no hay texto en el buscador, solo filtramos por estado
          if (_textoBusqueda.isEmpty) return coincideEstado;

          // Si hay texto, buscamos en el ID del pedido o el nombre (si lo tienes en el map)
          final idPedido = pedido['id'].toString().toLowerCase();
          // Nota: Para buscar por nombre de cliente, el pedido debería traer el nombre del perfil
          // Si no lo trae, el ID es lo más seguro por ahora.
          final coincideBusqueda = idPedido.contains(_textoBusqueda);

          return coincideEstado && coincideBusqueda;
        }).toList();

        if (pedidosFiltrados.isEmpty) {
          return _buildEstadoVacio("No se encontraron resultados");
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          itemCount: pedidosFiltrados.length,
          itemBuilder: (context, index) => _buildCardPedido(pedidosFiltrados[index]),
        );
      },
    );
  }

  Widget _buildCardPedido(Map<String, dynamic> pedido) {
    // Lógica para determinar si es urgente (ej. más de 15 min esperando)
    DateTime fechaPedido = DateTime.parse(pedido['fecha']);
    Duration diferencia = DateTime.now().difference(fechaPedido);
    bool esUrgent = diferencia.inMinutes > 20 && pedido['estado'] == 'pendiente';
    
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
                FutureBuilder<String>(
                  future: _pedidoService.obtenerNombreCliente(pedido['id_usuario']),
                  builder: (context, snapshot) {
                    // Mientras carga, mostramos un texto gris o un pequeño indicador
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text("Cargando cliente...", 
                          style: TextStyle(color: Colors.grey, fontSize: 13));
                    }

                    // Si hay datos, mostramos el nombre real del cliente
                    final nombre = snapshot.data ?? "Cliente desconocido";
                    return Text(
                      "Cliente: $nombre",
                      style: const TextStyle(
                        color: Colors.black54, 
                        fontWeight: FontWeight.w500,
                        fontSize: 14
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                
                // Sección de iconos de artículos (Simulada, requiere query a detalles_pedido)
                Row(
                  children: [
                    const Icon(Icons.shopping_basket_outlined, color: Colors.grey),
                    const SizedBox(width: 10),
                    // FutureBuilder para traer los nombres/iconos de los productos
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        // Query con JOIN: Trae la cantidad y el nombre del producto relacionado
                        future: _supabase
                            .from('detalles_pedido')
                            .select('cantidad, productos(nombre)')
                            .eq('fk_pedido', pedido['id']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text("Cargando...", style: TextStyle(fontSize: 12, color: Colors.grey));
                          }
                          
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text("Sin productos", style: TextStyle(fontSize: 12, color: Colors.grey));
                          }

                          final detalles = snapshot.data!;
                          
                          // Creamos una cadena de texto con los productos: "2x Pizza, 1x Coca-Cola"
                          String resumen = detalles.map((d) {
                            final nombre = d['productos']['nombre'];
                            final cant = d['cantidad'];
                            return "${cant}x $nombre";
                          }).join(", ");

                          return Text(
                            resumen,
                            overflow: TextOverflow.ellipsis, // Si son muchos, pone "..."
                            style: const TextStyle(
                              color: Colors.black87, 
                              fontSize: 13, 
                              fontWeight: FontWeight.w500
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Etiqueta del método de pago
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[200], 
                        borderRadius: BorderRadius.circular(5)
                      ),
                      child: Text(
                        pedido['metodo_pago'].toString().toUpperCase(), 
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                      ),
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

  Widget _buildEstadoVacio(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Un icono grande y suave para indicar vacío
            Icon(
              Icons.assignment_turned_in_outlined, 
              size: 80, 
              color: Colors.grey[300]
            ),
            const SizedBox(height: 15),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Cuando lleguen nuevos pedidos aparecerán aquí automáticamente.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Define qué botón mostrar según el estado actual
  Widget _buildBotonAccionPrincipal(Map<String, dynamic> pedido) {
    String estado = pedido['estado'];
    
    if (estado == "pendiente") {
      return ElevatedButton(
        onPressed: () => _actualizarEstado(pedido['id'], "preparacion"),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[600], foregroundColor: Colors.black),
        child: const Text("Empezar a Preparar"),
      );
    } else if (estado == "preparacion") {
      return ElevatedButton(
        onPressed: () => _actualizarEstado(pedido['id'], "listo"),
        style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(0, 180, 195, 1), foregroundColor: Colors.white),
        child: const Text("Marcar como Listo"),
      );
    } else {
      // Estado 'listo' u otros.
      return ElevatedButton(
        onPressed: () => _actualizarEstado(pedido['id'], "entregado"),
        style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 0, 153, 25), foregroundColor: Colors.white),
        child: const Text("entregado"),
      );
    }
  }

  // Ejemplo simple de cómo mostrar detalles (puedes crear una página nueva)
  void _mostrarDetallesPedido(Map<String, dynamic> pedido) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Ajusta el alto al contenido
          children: [
            Text(
              "Detalles Pedido #${pedido['id'].toString().substring(0, 5)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Notas: ${pedido['notas'] ?? 'Sin notas.'}", 
                 style: const TextStyle(color: Colors.grey)),
            const Divider(height: 30),
            
            // Lista de productos
            Flexible(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                // Traemos cantidad, precio y datos del producto (nombre e imagen)
                future: _supabase
                    .from('detalles_pedido')
                    .select('cantidad, precio_unitario, productos(nombre, imagen_url)')
                    .eq('fk_pedido', pedido['id']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No hay productos en este pedido."));
                  }

                  final productos = snapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: productos.length,
                    itemBuilder: (context, index) {
                      final item = productos[index];
                      final infoProd = item['productos'];
                      
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: infoProd['imagen_url'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    infoProd['imagen_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => 
                                      const Icon(Icons.fastfood),
                                  ),
                                )
                              : const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                        title: Text(
                          "${infoProd['nombre']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Cantidad: ${item['cantidad']}"),
                        trailing: Text(
                          "\$${(item['precio_unitario'] * item['cantidad']).toInt()}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: Color.fromRGBO(0, 180, 195, 1)
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // Botón para cerrar el modal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                ),
                child: const Text("Cerrar"),
              ),
            ),
          ],
        ),
      );
    },
  );
}
}