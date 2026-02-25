import 'package:flutter/material.dart';
import 'package:pbshop/widgets/mostrarestrellas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/servicios/CartService.dart' as CartServiceLib; // El único que debe traer CartService
import 'package:pbshop/pantallas/car_page.dart';    // Solo para la navegación

class product_page extends StatelessWidget {
  final Map producto;

  const product_page({super.key, required this.producto});

  // --- FUNCIÓN LÓGICA PARA AGREGAR AL CARRITO ---
  void _agregarAlPedido(BuildContext context) {
  CartServiceLib.CartService().agregarProducto({
    'id': producto['id'].toString(), // Forzamos a String
    'nombre': producto['nombre'],
    'precio': producto['precio'],
    'fk_negocio': producto['fk_negocio'], 
  });

    // 3. Feedback visual para el usuario
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Limpia notificaciones previas
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
            // Imagen del producto dinámica
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[200],
              child: producto['imagen_url'] != null
                  ? Image.network(producto['imagen_url'], fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 100, color: Colors.grey),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto['nombre'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("\$${producto['precio']}", style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(producto['descripcion'] ?? "Sin descripción disponible."),
                  const Divider(height: 40),
                  
                  const Text("Reseñas de la Comunidad", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  _seccionResenasReales(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0), // Aumenté un poco el padding para mejor estética
        child: ElevatedButton(
          // 4. LLAMADA A LA FUNCIÓN ACTUALIZADA
          onPressed: () => _agregarAlPedido(context), 
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
            minimumSize: const Size(double.infinity, 55), // Botón ligeramente más alto
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            "Agregar al Pedido", 
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
          ),
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