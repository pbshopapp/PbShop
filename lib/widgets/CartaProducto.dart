import 'package:flutter/material.dart';
import 'package:pbshop/pantallas/product_page.dart';
import 'package:pbshop/widgets/CuadroDeImagenes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartaProducto extends StatelessWidget {
  final Map<String, dynamic> producto;

  const CartaProducto({super.key, required this.producto});

  // Función para obtener las fotos de la tabla secundaria
  Future<List<String>> _obtenerFotos() async {
    try {
      final response = await Supabase.instance.client
          .from('imagenes_producto')
          .select('url')
          .eq('fk_producto', producto['id']);

      if (response == null) return [];
      return (response as List).map((item) => item['url'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => product_page(producto: producto),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECCIÓN DE IMAGEN DINÁMICA (CON SWIPE) ---
              SizedBox(
                height: 120, // Aumenté un poco el alto para que el slider se aprecie mejor
                width: double.infinity,
                child: FutureBuilder<List<String>>(
                  future: _obtenerFotos(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }

                    // Si hay varias fotos, usamos el CuadroDeImagenes
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return CuadroDeImagenes(
                        urls: snapshot.data!,
                        mostrarFlechas: false, // Solo deslizas con el dedo
                        mostrarPuntos: true,
                        );
                    }

                    // Respaldo: Imagen principal o icono si no hay nada
                    return Container(
                      color: Colors.grey[200],
                      child: producto['imagen_url'] != null && producto['imagen_url'].toString().isNotEmpty
                          ? Image.network(
                              producto['imagen_url'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                            )
                          : const Center(
                              child: Icon(Icons.fastfood, size: 40, color: Colors.grey),
                            ),
                    );
                  },
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
                    
                    // --- RATING ---
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          (producto['rating_promedio'] == null || producto['rating_promedio'] == 0)
                              ? "N/A"
                              : producto['rating_promedio'].toString(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 5),
                    Text(
                      '\$${(producto['precio'] as num).toInt()}', // Formateado sin decimales
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
      ),
    );
  }
}