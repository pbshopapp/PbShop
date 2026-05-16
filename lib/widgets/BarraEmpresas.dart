import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/pantallas/details_neg_page.dart';

class BarraEmpresas extends StatelessWidget {
  const BarraEmpresas({super.key});

  // Función para convertir el string de icono de la DB a un IconData real
  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'fastfood': return Icons.fastfood_rounded;
      case 'local_cafe': return Icons.local_cafe_rounded;
      case 'local_drink': return Icons.local_drink_rounded;
      case 'print': return Icons.print_rounded;
      case 'store': return Icons.store_rounded;
      default: return Icons.storefront_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color colorInstitucional = Color.fromRGBO(0, 180, 195, 1);
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 120, // Un poco más de altura para evitar cortes
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('negocios')
            .stream(primaryKey: ['id'])
            .order('nombre', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: colorInstitucional));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }

          final negocios = snapshot.data!;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: negocios.length,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemBuilder: (context, index) {
              final negocio = negocios[index];

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
                  width: 85,
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Círculo del icono con estilo "Clean"
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color.fromARGB(255, 249, 226, 172),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: esOscuro
                            ? const Color.fromARGB(255, 245, 207, 117)
                            : const Color.fromARGB(255, 245, 207, 117) ,
                          child: Icon(
                            _getIconData(negocio['icono']),
                            color: const Color.fromARGB(255, 255, 255, 255),
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Nombre del negocio
                      Text(
                        negocio['nombre'] ?? 'Negocio',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: esOscuro ? Colors.white : Colors.black87,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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