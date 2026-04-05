import 'package:flutter/material.dart';
import 'package:pbshop/pantallas/product_page.dart';
import 'package:pbshop/widgets/CuadroDeImagenes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Importamos intl

class CartaProducto extends StatelessWidget {
  final Map<String, dynamic> producto;
  // --- NUEVOS PARÁMETROS PARA ADMIN ---
  final bool esAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CartaProducto({
    super.key, 
    required this.producto,
    this.esAdmin = false, // Por defecto es falso para la tienda normal
    this.onEdit,
    this.onDelete,
  });

  Future<List<String>> _obtenerFotos() async {
    try {
      final response = await Supabase.instance.client
          .from('imagenes_producto')
          .select('url')
          .eq('fk_producto', producto['id']);

      return (response as List).map((item) => item['url'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formateador de moneda
    final monedaCop = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Material(
      type: MaterialType.transparency,
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: () {
            if (!esAdmin) { // Si es admin, quizás prefieras que no navegue al tocar
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => product_page(producto: producto)),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECCIÓN DE IMAGEN ---
              Stack(
                children: [
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: FutureBuilder<List<String>>(
                      future: _obtenerFotos(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                        }
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return CuadroDeImagenes(urls: snapshot.data!, mostrarPuntos: true);
                        }
                        return Container(
                          color: Colors.grey[200],
                          child: producto['imagen_url'] != null && producto['imagen_url'].toString().isNotEmpty
                              ? Image.network(producto['imagen_url'], fit: BoxFit.cover)
                              : const Center(child: Icon(Icons.fastfood, size: 40, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                  // --- BOTONES DE ADMIN FLOTANTES (OPCIONAL) ---
                  if (esAdmin)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Row(
                        children: [
                          _botonCircularAdmin(Icons.edit, Colors.blue, onEdit),
                          const SizedBox(width: 5),
                          _botonCircularAdmin(Icons.delete, Colors.red, onDelete),
                        ],
                      ),
                    ),
                ],
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
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // RATING
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
                        // PRECIO FORMATEADO CON INTL
                        Text(
                          monedaCop.format(producto['precio'] ?? 0),
                          style: const TextStyle(
                            color: Color.fromRGBO(0, 180, 195, 1), 
                            fontWeight: FontWeight.bold, 
                            fontSize: 14
                          )
                        ),
                      ],
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

  // Widget para los botones pequeños de admin sobre la imagen
  Widget _botonCircularAdmin(IconData icono, Color color, VoidCallback? accion) {
    return GestureDetector(
      onTap: accion,
      child: CircleAvatar(
        radius: 14,
        backgroundColor: Colors.white.withOpacity(0.9),
        child: Icon(icono, size: 16, color: color),
      ),
    );
  }
}