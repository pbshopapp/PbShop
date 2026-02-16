import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/pantallas/details_neg_page.dart';

class BarraEmpresas extends StatelessWidget {
  const BarraEmpresas({super.key});

  // Función para convertir el string de icono de la DB a un IconData real
  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'fastfood': return Icons.fastfood;
      case 'local_cafe': return Icons.local_cafe;
      case 'local_drink': return Icons.local_drink;
      case 'print': return Icons.print;
      case 'store': return Icons.store;
      default: return Icons.storefront; // Icono por defecto
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        // 1. Escuchamos la tabla 'negocios' en tiempo real
        stream: Supabase.instance.client
            .from('negocios')
            .stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink(); // No mostramos nada si no hay negocios
          }

          final negocios = snapshot.data!;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: negocios.length,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemBuilder: (context, index) {
              final negocio = negocios[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => details_neg_page(negocio: negocio),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green[100],
                        child: Icon(
                          _getIconData(negocio['icono']), // Usamos el nombre del icono guardado en DB
                          color: Colors.green[900]),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 70, // Limitamos el ancho para que el texto no choque
                        child: Text(
                          negocio['nombre'] ?? 'Negocio',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}