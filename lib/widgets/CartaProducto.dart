import 'package:flutter/material.dart';
import 'package:pbshop/pantallas/product_page.dart';
import 'package:pbshop/widgets/CuadroDeImagenes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CartaProducto extends StatelessWidget {
  final Map<String, dynamic> producto;
  final bool esAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CartaProducto({
    super.key, 
    required this.producto,
    this.esAdmin = false,
    this.onEdit,
    this.onDelete,
  });

  // MÉTODOS ASÍNCRONOS
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

  // 👇 NUEVO MÉTODO: Va a la tabla 'negocios' a traer la ubicación física
  Future<String> _obtenerUbicacionNegocio() async {
    try {
      // Si por alguna razón la vista ya la traía, la usamos de una vez
      if (producto['ubicacion_negocio'] != null) {
        return producto['ubicacion_negocio'].toString();
      }

      final idNegocio = producto['fk_negocio']; // Asegúrate de que este sea el nombre de la columna en tu tabla productos
      if (idNegocio == null) return 'Pascual Bravo';

      final response = await Supabase.instance.client
          .from('negocios')
          .select('ubicacion')
          .eq('id', idNegocio)
          .maybeSingle();

      if (response != null && response['ubicacion'] != null) {
        return response['ubicacion'].toString();
      }
      return 'Pascual Bravo';
    } catch (e) {
      debugPrint("Error obteniendo ubicación: $e");
      return 'Pascual Bravo';
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color colorInstitucional = Color.fromRGBO(0, 180, 195, 1);
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final monedaCop = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: esOscuro ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(esOscuro ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            if (!esAdmin) {
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
                    height: 130,
                    width: double.infinity,
                    child: FutureBuilder<List<String>>(
                      future: _obtenerFotos(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            color: esOscuro ? Colors.white10 : Colors.grey[100],
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: colorInstitucional)),
                          );
                        }
                        
                        final tieneUrls = snapshot.hasData && snapshot.data!.isNotEmpty;
                        final urlPrincipal = producto['imagen_url']?.toString();

                        if (tieneUrls) {
                          return CuadroDeImagenes(urls: snapshot.data!, mostrarPuntos: true);
                        }

                        return Container(
                          color: esOscuro ? Colors.white10 : Colors.grey[100],
                          child: (urlPrincipal != null && urlPrincipal.isNotEmpty)
                              ? Image.network(urlPrincipal, fit: BoxFit.cover)
                              : Icon(Icons.fastfood_rounded, size: 40, color: colorInstitucional.withOpacity(0.3)),
                        );
                      },
                    ),
                  ),
                  
                  if (esAdmin)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Row(
                        children: [
                          _botonCircularAdmin(Icons.edit_rounded, Colors.blue, onEdit),
                          const SizedBox(width: 8),
                          _botonCircularAdmin(Icons.delete_outline_rounded, Colors.redAccent, onDelete),
                        ],
                      ),
                    ),
                ],
              ),
              
              // --- DETALLES ---
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto['nombre'] ?? 'Producto', 
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // 👇 MODIFICACIÓN AQUÍ: Ubicación cargada dinámicamente con FutureBuilder
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: FutureBuilder<String>(
                            future: _obtenerUbicacionNegocio(),
                            builder: (context, snapshot) {
                              final textoUbicacion = snapshot.data ?? 'Cargando...';
                              return Text(
                                textoUbicacion, 
                                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 10),
                    Text(
                      monedaCop.format(producto['precio'] ?? 0),
                      style: const TextStyle(
                        color: colorInstitucional, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 15
                      ),
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

  Widget _botonCircularAdmin(IconData icono, Color color, VoidCallback? accion) {
    return GestureDetector(
      onTap: accion,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icono, size: 16, color: color),
      ),
    );
  }
}