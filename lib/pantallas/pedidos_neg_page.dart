import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _motivoController = TextEditingController();
  String _textoBusqueda = "";
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  final _pedidoService = PedidoService();

  String? _idNegocio;
  bool _cargando = true;

  // Color institucional turquesa
  final Color _colorInstitucional = const Color.fromRGBO(0, 180, 195, 1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _obtenerIdNegocio();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _obtenerIdNegocio() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('perfiles')
          .select('fk_negocio')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _idNegocio = data['fk_negocio'];
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint("Error obteniendo negocio: $e");
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _actualizarEstado(String pedidoId, String nuevoEstado, {String? motivo}) async {
    try {
      Map<String, dynamic> datosActualizar = {'estado': nuevoEstado};
      if (motivo != null) {
        datosActualizar['motivo_cancelacion'] = motivo;
      }

      final data = await _supabase
          .from('pedidos')
          .update(datosActualizar)
          .eq('id', pedidoId)
          .select();

      if (data.isNotEmpty) {
        HapticFeedback.mediumImpact(); // Retroalimentación táctil profesional
        if (mounted) setState(() {});
        _mostrarMensaje("Pedido $nuevoEstado correctamente", 
          nuevoEstado == "cancelado" ? Colors.red : Colors.green);
      }
    } catch (e) {
      _mostrarMensaje("Error: $e", Colors.red);
    }
  }

  void _confirmarCancelacion(String pedidoId) {
    _motivoController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Cancelar pedido?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Por favor, indica al estudiante el motivo:"),
            const SizedBox(height: 15),
            TextField(
              controller: _motivoController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Ej: Se agotó el ingrediente...",
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("VOLVER", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              if (_motivoController.text.trim().length < 5) {
                _mostrarMensaje("Escribe un motivo más detallado", Colors.orange);
                return;
              }
              _actualizarEstado(pedidoId, "cancelado", motivo: _motivoController.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("CONFIRMAR", style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    if (_cargando) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: _colorInstitucional)));
    }

    return Scaffold(
      backgroundColor: esOscuro ? Colors.black : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _colorInstitucional,
        centerTitle: false,
        title: _estaBuscando 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Buscar pedido...",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onChanged: (val) => setState(() => _textoBusqueda = val.toLowerCase()),
            )
          : const Text("Pedidos", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(_estaBuscando ? Icons.close : Icons.search_rounded, color: Colors.white),
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: "Pendientes"),
            Tab(text: "En Proceso"),
            Tab(text: "Listos"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
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
          .from('pedidos_detallados')
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

        final pedidosFiltrados = snapshot.data!.where((pedido) {
          final coincideEstado = pedido['estado'].toString().toLowerCase() == estadoFiltro;
          if (_textoBusqueda.isEmpty) return coincideEstado;
          final idPedido = pedido['id'].toString().toLowerCase();
          final nombreCliente = (pedido['nombre_cliente'] ?? "").toString().toLowerCase();
          return coincideEstado && (idPedido.contains(_textoBusqueda) || nombreCliente.contains(_textoBusqueda));
        }).toList();

        if (pedidosFiltrados.isEmpty) {
          return _buildEstadoVacio("No se encontraron resultados");
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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
    String metodoPago = (pedido['metodo_pago'] ?? '').toString().toLowerCase();
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: esOscuro ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
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
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: esUrgent ? Colors.red : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "Hace ${diferencia.inMinutes} min ($horaFormateada)",
                            style: TextStyle(color: esUrgent ? Colors.red : Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: esUrgent ? Colors.red.withOpacity(0.1) : _colorInstitucional.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      esUrgent ? "URGENTE" : "NORMAL",
                      style: TextStyle(color: esUrgent ? Colors.red : _colorInstitucional, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: _colorInstitucional.withOpacity(0.1),
                        child: Icon(Icons.person, size: 14, color: _colorInstitucional),
                      ),
                      const SizedBox(width: 8),
                      FutureBuilder<String>(
                        future: _pedidoService.obtenerNombreCliente(pedido['id_usuario']),
                        builder: (context, snapshot) => Text(
                          snapshot.data ?? "Cargando...",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      Text("\$${(pedido['total'] as num).toInt()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("PAGO: ${metodoPago.toUpperCase()}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                      if (metodoPago == 'transferencia')
                        InkWell(
                          onTap: () {
                            final url = pedido['comprobante_url'];
                            if (url != null && url != 'null') _mostrarImagenComprobante(url);
                            else _mostrarMensaje("Sin comprobante", Colors.orange);
                          },
                          child: Text("VER COMPROBANTE", style: TextStyle(color: _colorInstitucional, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (pedido['estado'] != 'entregado')
                    Material(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      child: IconButton(
                        onPressed: () => _confirmarCancelacion(pedido['id']),
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(child: _crearBotonSegunEstado(pedido['estado'], pedido['id'])),
                  const SizedBox(width: 12),
                  Material(
                    color: esOscuro ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    child: IconButton(
                      onPressed: () => _mostrarDetallesPedido(pedido),
                      icon: const Icon(Icons.remove_red_eye_outlined),
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

  Widget _crearBotonSegunEstado(String estado, String id) {
    Color color = _colorInstitucional;
    String texto = "LISTO";
    
    if (estado == "pendiente") {
      color = Colors.orange;
      texto = "PREPARAR";
    } else if (estado == "listo") {
      color = Colors.green;
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

  void _mostrarImagenComprobante(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            const SizedBox(height: 10),
            CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoVacio(String mensaje) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(mensaje, style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _mostrarDetallesPedido(Map<String, dynamic> pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Detalles Pedido #${pedido['id'].toString().substring(0, 5)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Notas: ${pedido['notas'] ?? 'Sin notas adicionales.'}", style: const TextStyle(color: Colors.grey)),
              const Divider(height: 40),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _supabase.from('detalles_pedido').select('cantidad, precio_unitario, productos(nombre, imagen_url)').eq('fk_pedido', pedido['id']),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final item = snapshot.data![index];
                        
                        // 1. BLINDAJE: Extraemos la relación de productos de forma segura
                        final Map<String, dynamic>? productoData = item['productos'] as Map<String, dynamic>?;

                        // 2. Extracción de valores individuales con plan de respaldo (Fallback)
                        final String nombreProducto = productoData?['nombre']?.toString() ?? 'Producto no disponible';
                        final String? urlImagen = productoData?['imagen_url']?.toString();

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: urlImagen != null && urlImagen.isNotEmpty
                                ? Image.network(
                                    urlImagen, 
                                    width: 50, 
                                    height: 50, 
                                    fit: BoxFit.cover, 
                                    errorBuilder: (_, __, ___) => const Icon(Icons.fastfood),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.fastfood, color: Colors.grey),
                                  ),
                          ),
                          title: Text(
                            nombreProducto, 
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                          subtitle: Text("Cantidad: ${item['cantidad']}"),
                          trailing: Text(
                            "\$${((item['precio_unitario'] ?? 0) * (item['cantidad'] ?? 0)).toInt()}", 
                            style: TextStyle(color: _colorInstitucional, fontWeight: FontWeight.bold)
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}