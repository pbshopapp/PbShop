import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/widgets/CartaNegocio.dart';
import 'package:pbshop/widgets/EncabezadoAnimado.dart'; 
import 'package:pbshop/servicios/HorarioHelper.dart'; // 👈 Importamos el Helper para validar los locales

class shops_page extends StatelessWidget {
  const shops_page({super.key});

  @override
  Widget build(BuildContext context) {
    const Color colorInstitucional = Color.fromRGBO(0, 180, 195, 1);
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: esOscuro ? Colors.black : const Color(0xFFF8F9FA),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('negocios')
            .stream(primaryKey: ['id'])
            .order('nombre', ascending: true),
        builder: (context, snapshot) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. EL ENCABEZADO ANIMADO
              const EncabezadoAnimado(
                titulo: "Tiendas de la U",
                subtitulo: "El aliado del parche pascualino.",
                mostrarLogo: true,
              ),

              // 2. MANEJO DE ESTADOS (Carga o Vacío)
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: colorInstitucional)),
                )
              else if (!snapshot.hasData || snapshot.data!.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else ...[
                // 3. LA CUADRÍCULA DE TIENDAS
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Creamos una copia mutable del mapa del negocio para poder inyectar datos localmente
                        final Map<String, dynamic> negocio = Map<String, dynamic>.from(snapshot.data![index]);
                        
                        // Extraemos el horario guardado en la base de datos o por defecto "24 Horas"
                        final String horarioLocal = negocio['horario']?.toString() ?? "24 Horas";
                        
                        // 👈 Inyectamos la validación del HorarioHelper en el mapa del negocio
                        negocio['esta_abierto'] = HorarioHelper.estaAbierto(horarioLocal);

                        return Hero(
                          tag: 'negocio_${negocio['id']}',
                          child: CartaNegocio(negocio: negocio),
                        );
                      },
                      childCount: snapshot.data!.length,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // Widget para mostrar cuando no hay datos
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 80, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text(
            "No hay tiendas registradas aún.",
            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}