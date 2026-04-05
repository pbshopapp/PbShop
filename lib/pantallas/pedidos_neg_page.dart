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

  // Función para confirmar y ejecutar la cancelación
  void _confirmarCancelacion(String pedidoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Cancelar pedido?"),
        content: const Text("Esta acción le avisará al estudiante que su pedido no puede ser procesado."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("VOLVER"),
          ),
          ElevatedButton(
            onPressed: () {
              _actualizarEstado(pedidoId, "cancelado");
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("SÍ, CANCELAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
    backgroundColor: const Color(0xFFF8F9FA), // Fondo gris claro para que las tarjetas blancas resalten
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromRGBO(0, 180, 195, 1), // Fondo blanco para mayor claridad
        foregroundColor: const Color.fromARGB(255, 255, 255, 255), // Iconos y texto en negro
        title: _estaBuscando 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Buscar pedido...",
                border: InputBorder.none,
              ),
              onChanged: (val) => setState(() => _textoBusqueda = val.toLowerCase()),
            )
          : const Text(
              "Pedidos", 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)
            ),
        actions: [
          IconButton(
            icon: Icon(_estaBuscando ? Icons.close : Icons.search_rounded),
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
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true, // Permite que los tabs no se amontonen
              tabAlignment: TabAlignment.start,
              indicatorColor: const Color.fromARGB(255, 255, 255, 255),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.black,
              unselectedLabelColor: const Color.fromARGB(255, 255, 255, 255),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: const [
                Tab(text: "Pendientes"),
                Tab(text: "En Proceso"),
                Tab(text: "Listos"),
              ],
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
          .from('pedidos_detallados') // <--- Usa la vista, no la tabla
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
          
          if (_textoBusqueda.isEmpty) return coincideEstado;

          // Búsqueda por ID o por Nombre del Cliente
          final idPedido = pedido['id'].toString().toLowerCase();
          final nombreCliente = (pedido['nombre_cliente'] ?? "").toString().toLowerCase();

          final coincideBusqueda = idPedido.contains(_textoBusqueda) || 
                                  nombreCliente.contains(_textoBusqueda);

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
    DateTime fechaPedido = DateTime.parse(pedido['fecha']);
    Duration diferencia = DateTime.now().difference(fechaPedido);
    bool esUrgent = diferencia.inMinutes > 20 && pedido['estado'] == 'pendiente';
    String horaFormateada = DateFormat('jm').format(fechaPedido.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Header de la tarjeta con Badge de tiempo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pedido #${pedido['id'].toString().substring(0, 5).toUpperCase()}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: esUrgent ? Colors.red : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "Hace ${diferencia.inMinutes} min ($horaFormateada)",
                            style: TextStyle(color: esUrgent ? Colors.red : Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: esUrgent ? Colors.red[50] : Colors.teal[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      esUrgent ? "URGENTE" : "NORMAL",
                      style: TextStyle(
                        color: esUrgent ? Colors.red[700] : Colors.teal[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // Cuerpo: Información del Cliente y Productos
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del Cliente con Avatar Genérico
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color.fromRGBO(0, 180, 195, 0.1),
                        child: const Icon(Icons.person, size: 14, color: Color.fromRGBO(0, 180, 195, 1)),
                      ),
                      const SizedBox(width: 8),
                      FutureBuilder<String>(
                        future: _pedidoService.obtenerNombreCliente(pedido['id_usuario']),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? "Cargando...",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          );
                        },
                      ),
                      const Spacer(),
                      Text(
                        "\$${(pedido['total'] as num).toInt()}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // Lista de productos compacta
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _supabase
                        .from('detalles_pedido')
                        .select('cantidad, productos(nombre)')
                        .eq('fk_pedido', pedido['id']),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: snapshot.data!.map((d) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              "${d['cantidad']}x ${d['productos']['nombre']}",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Botones de Acción con estilo moderno
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Botón Cancelar (Icono sutil)
                  if (pedido['estado'] != 'entregado')
                    Material(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      child: IconButton(
                        onPressed: () => _confirmarCancelacion(pedido['id']),
                        icon: const Icon(Icons.close, color: Colors.red),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  const SizedBox(width: 12),
                  
                  // Botón Principal
                  Expanded(child: _crearBotonSegunEstado(pedido['estado'], pedido['id'])),
                  
                  const SizedBox(width: 12),

                  // Botón Detalles
                  Material(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    child: IconButton(
                      onPressed: () => _mostrarDetallesPedido(pedido),
                      icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.black54),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
  /*Widget _buildBotonAccionPrincipal(Map<String, dynamic> pedido) {
    String estado = pedido['estado'];
    String id = pedido['id'];

    return Row(
      children: [
        // BOTÓN DE CANCELAR (Solo aparece si NO está entregado ni cancelado)
        if (estado != 'entregado' && estado != 'cancelado')
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: () => _confirmarCancelacion(id),
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              tooltip: "Cancelar Pedido",
            ),
          ),
        
        // BOTÓN DE ACCIÓN PRINCIPAL
        Expanded(
          child: _crearBotonSegunEstado(estado, id),
        ),
      ],
    );
  }*/

  // Método auxiliar para limpiar el switch anterior
  Widget _crearBotonSegunEstado(String estado, String id) {
    Color color;
    String texto;
    
    if (estado == "pendiente") {
      color = Colors.orange[400]!;
      texto = "PREPARAR";
    } else if (estado == "preparacion") {
      color = const Color.fromRGBO(0, 180, 195, 1);
      texto = "LISTO";
    } else {
      color = Colors.green[600]!;
      texto = "ENTREGAR";
    }

    return ElevatedButton(
      onPressed: () => _actualizarEstado(id, estado == "pendiente" ? "preparacion" : (estado == "preparacion" ? "listo" : "entregado")),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
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