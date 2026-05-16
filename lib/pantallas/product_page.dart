import 'package:flutter/material.dart';
import 'package:pbshop/widgets/mostrarestrellas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/servicios/CartService.dart' as CartServiceLib;
import 'package:pbshop/widgets/CuadroDeImagenes.dart';
import 'package:intl/intl.dart';

class product_page extends StatefulWidget {
  final Map producto;
  const product_page({super.key, required this.producto});

  @override
  State<product_page> createState() => _product_pageState();
}

class _product_pageState extends State<product_page> {
  bool _estaProcesando = false;
  final f = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  // Color institucional turquesa
  final Color _colorInstitucional = const Color.fromRGBO(0, 180, 195, 1);

  Future<List<String>> _obtenerFotos() async {
    try {
      final String productoId = widget.producto['id'].toString();
      final response = await Supabase.instance.client
          .from('imagenes_producto')
          .select('url')
          .eq('fk_producto', productoId)
          .timeout(const Duration(seconds: 4));

      final listaUrls = (response as List).map((item) => item['url'].toString()).toList();
      if (listaUrls.isEmpty && widget.producto['imagen_url'] != null) {
        return [widget.producto['imagen_url']];
      }
      return listaUrls;
    } catch (e) {
      return [widget.producto['imagen_url'] ?? ''];
    }
  }

  @override
  Widget build(BuildContext context) {
    final String imagenSegura = widget.producto['imagen_url'] ?? '';
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: esOscuro ? Colors.black : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: esOscuro ? Colors.black54 : Colors.white.withOpacity(0.9), 
            shape: BoxShape.circle
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: esOscuro ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 40), 
            // --- IMAGENES ---
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              child: FutureBuilder<List<String>>(
                future: _obtenerFotos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: _colorInstitucional));
                  }
                  final urls = snapshot.data ?? [imagenSegura];
                  return CuadroDeImagenes(urls: urls);
                },
              ),
            ),

            // --- PANEL DE INFORMACIÓN ---
            Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
                decoration: BoxDecoration(
                  color: esOscuro ? const Color(0xFF121212) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), 
                      blurRadius: 10, 
                      offset: const Offset(0, -5)
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.producto['nombre'] ?? '',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                        ),
                        Text(
                          f.format(widget.producto['precio']),
                          style: TextStyle(fontSize: 22, color: _colorInstitucional, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildBadgeTienda(esOscuro),
                    const SizedBox(height: 30),
                    const Text("Descripción", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      widget.producto['descripcion'] ?? "Este producto no tiene descripción.",
                      style: TextStyle(
                        fontSize: 15, 
                        color: esOscuro ? Colors.grey[400] : Colors.grey[700], 
                        height: 1.6
                      ),
                    ),
                    const SizedBox(height: 35),
                    const Text("Reseñas de la comunidad", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _seccionResenasReales(esOscuro),
                    const SizedBox(height: 120), 
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBarraAccionCompra(esOscuro),
    );
  }

  Widget _buildBadgeTienda(bool esOscuro) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: esOscuro ? Colors.grey[900] : Colors.grey[100], 
        borderRadius: BorderRadius.circular(15)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront, size: 18, color: _colorInstitucional),
          const SizedBox(width: 8),
          Text(
            "Vendido por ${widget.producto['nombre_negocio']}", 
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)
          ),
        ],
      ),
    );
  }

  Widget _buildBarraAccionCompra(bool esOscuro) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esOscuro ? const Color(0xFF121212) : Colors.white,
        border: Border(top: BorderSide(color: esOscuro ? Colors.white10 : Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: ElevatedButton(
  // Si está procesando en la BD, lo deshabilitamos por completo nativamente pasando null
  onPressed: _estaProcesando 
      ? null 
      : () {
          // 1. EXTRAER ESTADO DE APERTURA (Asegúrate de cómo se llama en tu widget, ej: widget.producto)
          final bool estaAbierto = widget.producto['esta_abierto'] ?? true;

          // 2. CANDADO DE SEGURIDAD: Validar PRIMERO si está cerrado antes de alterar estados
          if (!estaAbierto) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.store_rounded, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text("Tienda Cerrada"),
                  ],
                ),
                content: const Text(
                  "Lo sentimos, este emprendimiento se encuentra fuera de su horario de atención y no está recibiendo pedidos en este momento.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Entendido", 
                      style: TextStyle(color: Color.fromRGBO(0, 180, 195, 1), fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            );
            
            // Rompemos la ejecución de inmediato. Al estar '_estaProcesando' en false, 
            // el botón conserva su estado natural y no se queda congelado.
            return; 
          }

          // 3. SI ESTÁ ABIERTO: Procedemos con tu flujo normal de compra
          _agregarAlPedido(context);
        },
  style: ElevatedButton.styleFrom(
    backgroundColor: (widget.producto['esta_abierto'] ?? true) 
        ? _colorInstitucional 
        : Colors.grey[400], // Se pone gris si está cerrado
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 60),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  child: _estaProcesando 
    ? const SizedBox(
        height: 25, 
        width: 25, 
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
      )
    : Text(
        (widget.producto['esta_abierto'] ?? true) ? "Agregar al carrito" : "Local Cerrado",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
),
      ),
    );
  }

  void _agregarAlPedido(BuildContext context) {
    setState(() => _estaProcesando = true);
    try {
      CartServiceLib.CartService().agregarProducto({
        'id': widget.producto['id'].toString(),
        'nombre': widget.producto['nombre'],
        'precio': (widget.producto['precio'] as num).toDouble(),
        'fk_negocio': widget.producto['fk_negocio'],
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("¡Producto añadido con éxito!", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF007025),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
        )
      );
    } finally {
      setState(() => _estaProcesando = false);
    }
  }

  Widget _seccionResenasReales(bool esOscuro) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('resenas')
          .stream(primaryKey: ['id'])
          .eq('fk_producto', widget.producto['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.grey[50], 
              borderRadius: BorderRadius.circular(20)
            ),
            child: const Center(
              child: Text("Aún no hay opiniones. ¡Sé el primero!", style: TextStyle(fontStyle: FontStyle.italic))
            ),
          );
        }
        return Column(
          children: snapshot.data!.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: esOscuro ? Colors.white.withOpacity(0.05) : Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mostrarEstrellas(r['puntuacion'] ?? 0),
                const SizedBox(height: 10),
                Text(
                  r['comentario'] ?? "", 
                  style: TextStyle(
                    fontSize: 14, 
                    fontStyle: FontStyle.italic,
                    color: esOscuro ? Colors.grey[300] : Colors.black87
                  )
                ),
              ],
            ),
          )).toList(),
        );
      },
    );
  }
}