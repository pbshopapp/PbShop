import 'package:flutter/material.dart';
import 'package:pbshop/widgets/mostrarestrellas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/servicios/CartService.dart' as CartServiceLib;
import 'package:pbshop/widgets/CuadroDeImagenes.dart';

class product_page extends StatefulWidget {
  final Map producto;
  const product_page({super.key, required this.producto});

  @override
  State<product_page> createState() => _product_pageState();
}

class _product_pageState extends State<product_page> {
  bool _estaProcesando = false;

  // REVISIÓN: Aseguramos que el ID sea String para evitar errores de tipo en el query
  Future<List<String>> _obtenerFotos() async {
    try {
      final String productoId = widget.producto['id'].toString();
      
      final response = await Supabase.instance.client
          .from('imagenes_producto')
          .select('url')
          .eq('fk_producto', productoId)
          .timeout(const Duration(seconds: 4));

      final listaUrls = (response as List).map((item) => item['url'].toString()).toList();
      
      // Si no hay fotos adicionales, metemos la foto principal al menos para que el widget no esté vacío
      if (listaUrls.isEmpty && widget.producto['imagen_url'] != null) {
        return [widget.producto['imagen_url']];
      }
      
      return listaUrls;
    } catch (e) {
      debugPrint("Error en detalle de producto: $e");
      return []; 
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extraemos la imagen que YA FUNCIONA en la carta para tenerla de respaldo inmediato
    final String imagenSegura = widget.producto['imagen_url'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.producto['nombre'] ?? 'Producto'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- EL WIDGET CRÍTICO ---
            SizedBox(
              height: 280,
              width: double.infinity,
              child: FutureBuilder<List<String>>(
                future: _obtenerFotos(),
                builder: (context, snapshot) {
                  // Si hay un error o aún está cargando, mostramos la imagen que YA FUNCIONA
                  if (snapshot.connectionState == ConnectionState.waiting || snapshot.hasError) {
                    return _buildImagenSimple(imagenSegura);
                  }

                  // Si tenemos datos y el widget CuadroDeImagenes no falla
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    try {
                      return CuadroDeImagenes(urls: snapshot.data!);
                    } catch (e) {
                      return _buildImagenSimple(imagenSegura);
                    }
                  }

                  // Por defecto, imagen segura
                  return _buildImagenSimple(imagenSegura);
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.producto['nombre'] ?? '',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "\$${(widget.producto['precio'] as num).toInt()}",
                    style: const TextStyle(fontSize: 22, color: Color.fromRGBO(0, 180, 195, 1), fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 40),
                  const Text("Descripción", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(widget.producto['descripcion'] ?? "Sin descripción", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 30),
                  _seccionResenasReales(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBotonCompra(),
    );
  }

  // WIDGET DE RESPALDO (Usa Image.network igual que la carta)
  Widget _buildImagenSimple(String url) {
    if (url.isEmpty) return const Center(child: Icon(Icons.image, size: 100));
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 100),
    );
  }

  // Resto de lógica (Carrito y Reseñas) idéntica a la anterior...
  Widget _buildBotonCompra() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _estaProcesando ? null : () => _agregarAlPedido(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _estaProcesando 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("Agregar al Pedido", style: TextStyle(color: Colors.white, fontSize: 18)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Agregado al pedido")));
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text("Sin reseñas.");
        return Column(
          children: snapshot.data!.map((r) => ListTile(
            title: mostrarEstrellas(r['puntuacion'] ?? 0),
            subtitle: Text(r['comentario'] ?? ""),
          )).toList(),
        );
      },
    );
  }
}