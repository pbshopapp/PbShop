import 'package:flutter/material.dart';
import 'package:pbshop/pantallas/details_neg_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartaNegocio extends StatelessWidget {
  final Map<String, dynamic> negocio;

  const CartaNegocio({super.key, required this.negocio});

  // Función para obtener el promedio de estrellas desde Supabase
  Future<double> _obtenerPromedioEstrellas() async {
    try {
      final res = await Supabase.instance.client
          .from('resenas')
          .select('puntuacion')
          .eq('fk_negocio', negocio['id']);
      
      if (res == null || (res as List).isEmpty) return 0.0;
      
      final lista = res as List;
      double suma = lista.fold(0, (prev, element) => prev + (element['puntuacion'] ?? 0));
      return suma / lista.length;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color colorInstitucional = Color.fromRGBO(0, 180, 195, 1);
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsNegPage(negocio: negocio),
          ),
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PARTE SUPERIOR: IMAGEN Y BADGE ---
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: esOscuro ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: negocio['imagen_url'] != null 
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.network(
                            negocio['imagen_url'], 
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Icon(Icons.storefront_rounded, size: 40, color: colorInstitucional.withOpacity(0.5)),
                  ),
                  // Indicador de Estrellas / Nuevo
                  Positioned(
                    top: 10,
                    right: 10,
                    child: FutureBuilder<double>(
                      future: _obtenerPromedioEstrellas(),
                      builder: (context, snapshot) {
                        double promedio = snapshot.data ?? 0.0;
                        bool esNuevo = promedio == 0;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                esNuevo ? Icons.fiber_new_rounded : Icons.star_rounded, 
                                color: esNuevo ? Colors.blue : Colors.amber, 
                                size: 16
                              ),
                              if (!esNuevo) const SizedBox(width: 2),
                              if (!esNuevo)
                                Text(
                                  promedio.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 11, 
                                    fontWeight: FontWeight.bold, 
                                    color: Colors.black87
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // --- PARTE INFERIOR: TEXTO ---
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      negocio['nombre'] ?? 'Negocio PB',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            negocio['ubicacion'] ?? 'Pascual Bravo',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Badge de Categoría
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorInstitucional.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (negocio['categoria'] ?? 'General').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 8, 
                          color: colorInstitucional, 
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}