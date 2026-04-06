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
    final colorPrimario = const Color.fromRGBO(0, 180, 195, 1);

    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar transparente para que la imagen sea la protagonista
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40), // Espacio para que el contenido no quede debajo del AppBar
            // --- CABECERA: IMAGEN ---
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              child: FutureBuilder<List<String>>(
                future: _obtenerFotos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(color: Colors.grey[100], child: const Center(child: CircularProgressIndicator()));
                  }
                  final urls = snapshot.data ?? [imagenSegura];
                  return CuadroDeImagenes(urls: urls);
                },
              ),
            ),

            // --- CUERPO: INFORMACIÓN ---
            Transform.translate(
              offset: const Offset(0, -30), // Sube el panel sobre la imagen
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título y Precio en una fila
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.producto['nombre'] ?? '',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                          ),
                        ),
                        Text(
                          f.format(widget.producto['precio']),
                          style: TextStyle(fontSize: 24, color: colorPrimario, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Badge de la tienda (Opcional, mejora la confianza)
                    _buildBadgeTienda(),

                    const SizedBox(height: 25),
                    const Text("Descripción", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      widget.producto['descripcion'] ?? "Este producto no tiene descripción.",
                      style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                    ),

                    const SizedBox(height: 35),
                    const Text("Reseñas de la comunidad", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _seccionResenasReales(),
                    const SizedBox(height: 100), // Espacio para que el botón no tape nada
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBarraAccionCompra(colorPrimario),
    );
  }

  Widget _buildBadgeTienda() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text("Vendido por ${widget.producto['nombre_negocio']}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBarraAccionCompra(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _estaProcesando ? null : () => _agregarAlPedido(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: _estaProcesando 
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Agregar al carrito", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // Lógica de agregar al pedido
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
          content: const Text("¡Producto añadido!"),
          backgroundColor: const Color.fromARGB(221, 0, 112, 37),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
      );
    } finally {
      setState(() => _estaProcesando = false);
    }
  }

  Widget _seccionResenasReales() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('resenas')
          .stream(primaryKey: ['id'])
          .eq('fk_producto', widget.producto['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15)),
            child: const Center(child: Text("Aún no hay opiniones. ¡Sé el primero!")),
          );
        }
        return Column(
          children: snapshot.data!.map((r) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.grey[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: mostrarEstrellas(r['puntuacion'] ?? 0),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(r['comentario'] ?? "", style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
          )).toList(),
        );
      },
    );
  }
}