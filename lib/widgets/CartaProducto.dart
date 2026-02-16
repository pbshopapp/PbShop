import 'package:flutter/material.dart';
import 'package:pbshop/pantallas/product_page.dart'; 

class CartaProducto extends StatelessWidget {
  final Map<String, dynamic> producto;

  const CartaProducto({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => product_page(producto: producto),
          ),
        );
      },
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECCIÓN DE IMAGEN DINÁMICA ---
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
              ),
              child: producto['imagen_url'] != null && producto['imagen_url'].toString().isNotEmpty
                  ? Image.network(
                      producto['imagen_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                    )
                  : const Center(
                      child: Icon(Icons.fastfood, size: 50, color: Colors.grey),
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['nombre'] ?? 'Sin nombre', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                        producto['ubicacion_negocio'] ?? 'Ubicación no disponible', 
                        style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  const SizedBox(height: 4),
                  
                  // --- SECCIÓN DE RATING DESDE LA VISTA ---
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        // Usamos 'rating_promedio' que es el nombre de la columna en la vista SQL
                        (producto['rating_promedio'] == null || producto['rating_promedio'] == 0)
                            ? "N/A"
                            : producto['rating_promedio'].toString(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 5),
                  Text(
                    '\$${producto['precio']}', 
                    style: const TextStyle(
                      color: Color.fromRGBO(0, 180, 195, 1), 
                      fontWeight: FontWeight.bold, 
                      fontSize: 15
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}