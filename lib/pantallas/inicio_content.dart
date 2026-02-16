import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/widgets/CartaProducto.dart';
import 'package:pbshop/widgets/BarraEmpresas.dart';
import 'package:pbshop/widgets/EncabezadoAnimado.dart';
import 'package:pbshop/widgets/BuscadorWidget.dart';

class InicioContent extends StatelessWidget {
  const InicioContent({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const EncabezadoAnimado(),
        SliverToBoxAdapter(
          child: Column(
            children: const [
              BuscadorWidget(),
              BarraEmpresas(),
            ],
          ),
        ),
        
        // El StreamBuilder para traer datos reales de Supabase
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('v_productos_con_rating') 
              .stream(primaryKey: ['id']),
          builder: (context, snapshot) {
            // 1. Mientras carga
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            // 2. Si hay error o está vacío
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("No hay productos disponibles"),
                  ),
                ),
              );
            }

            // 3. ALEATORIEDAD: Barajamos la lista real de la DB
            final productos = snapshot.data!;
            productos.shuffle(); 

            return SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Ahora pasamos el mapa real de la base de datos
                    return CartaProducto(producto: productos[index]);
                  },
                  childCount: productos.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}