import 'package:flutter/material.dart';
import 'package:pbshop/widgets/mostrarestrellas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/servicios/CartService.dart' as CartServiceLib;
import 'package:pbshop/pantallas/car_page.dart';
import 'package:pbshop/widgets/CuadroDeImagenes.dart';

class product_page extends StatelessWidget {
  final Map producto;

  const product_page({super.key, required this.producto});

  // FUNCIÓN PARA TRAER LAS URLS DE LAS IMÁGENES DESDE LA TABLA SECUNDARIA
  Future<List<String>> _obtenerFotos() async {
    try {
      final response = await Supabase.instance.client
          .from('imagenes_producto')
          .select('url')
          .eq('fk_producto', producto['id']);

      if (response == null) return [];
      
      // Convertimos la lista de mapas en una lista de Strings (URLs)
      return (response as List).map((item) => item['url'] as String).toList();
    } catch (e) {
      debugPrint("Error obteniendo fotos: $e");
      return [];
    }
  }

  // --- FUNCIÓN LÓGICA PARA AGREGAR AL CARRITO ---
  void _agregarAlPedido(BuildContext context) {

    final double precioCorregido = (producto['precio'] as num).toDouble();

    CartServiceLib.CartService().agregarProducto({
      'id': producto['id'].toString(),
      'nombre': producto['nombre'],
      'precio': precioCorregido, 
      'fk_negocio': producto['fk_negocio'],
    });

    // Feedback visual para el usuario
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ ${producto['nombre']} agregado"),
        backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: "VER CARRITO",
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const car_page()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(producto['nombre'])),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- VISOR DE IMÁGENES DINÁMICO ---
            FutureBuilder<List<String>>(
              future: _obtenerFotos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                // Si encontramos imágenes en la tabla 'imagenes_producto'
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return CuadroDeImagenes(urls: snapshot.data!);
                }

                // Si no hay imágenes en la tabla, usamos la 'imagen_url' principal como respaldo
                return Container(
                  height: 250,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: producto['imagen_url'] != null
                      ? Image.network(producto['imagen_url'], fit: BoxFit.cover)
                      : const Icon(Icons.image, size: 100, color: Colors.grey),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto['nombre'],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  
                  // Mostramos el precio formateado (sin decimales innecesarios)
                  Text("\$${(producto['precio'] as num).toInt()}",
                      style: const TextStyle(
                          fontSize: 20,
                          color: Colors.green,
                          fontWeight: FontWeight.bold)),
                  
                  const SizedBox(height: 10),
                  Text(producto['descripcion'] ?? "Sin descripción disponible."),
                  const Divider(height: 40),

                  const Text("Reseñas de la Comunidad",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  _seccionResenasReales(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () => _agregarAlPedido(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Agregar al Pedido",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _seccionResenasReales() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('resenas')
          .stream(primaryKey: ['id'])
          .eq('fk_producto', producto['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("Este producto aún no tiene reseñas. ¡Sé el primero!",
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          );
        }

        final resenas = snapshot.data!;

        return Column(
          children: resenas.map((resena) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: mostrarEstrellas(resena['puntuacion'] ?? 0),
              subtitle: Text(resena['comentario'] ?? ""),
              leading: const CircleAvatar(
                backgroundColor: Color.fromRGBO(0, 180, 195, 0.1),
                child: Icon(Icons.person, color: Color.fromRGBO(0, 180, 195, 1)),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}