import 'package:flutter/material.dart';
import 'package:pbshop/widgets/mostrarestrellas.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importante importar Supabase

class product_page extends StatelessWidget {
  final Map producto;

  const product_page({super.key, required this.producto});

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
                  
                  // --- AQUÍ EL CAMBIO REAL: STREAM DE RESEÑAS ---
                  _seccionResenasReales(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(

        padding: const EdgeInsets.all(8.0),

        child: ElevatedButton(

          onPressed: () {}, // Aquí irá la lógica de agregar al carrito

          style: ElevatedButton.styleFrom(

            backgroundColor: const Color.fromRGBO(0, 180, 195, 1),

            minimumSize: const Size(double.infinity, 50),

          ),

          child: const Text("Agregar al Pedido", style: TextStyle(color: Colors.white)),

        ),

      ),
    );
  }

  Widget _seccionResenasReales() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // Filtramos las reseñas: traeme solo las donde fk_producto sea igual al id de este producto
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
              // Usamos tu widget para mostrar las estrellas según la puntuación de la DB
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