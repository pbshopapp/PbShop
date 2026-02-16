import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/widgets/CartaProducto.dart'; // Reutilizamos tu widget de productos

class details_neg_page extends StatelessWidget {
  final Map<String, dynamic> negocio;

  const details_neg_page({super.key, required this.negocio});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Banner Superior con el nombre
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(negocio['nombre'], 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  negocio['imagen_url'] != null
                      ? Image.network(negocio['imagen_url'], fit: BoxFit.cover)
                      : Container(color: const Color.fromRGBO(0, 180, 195, 1)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Información del Negocio
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 5),
                      Text(negocio['ubicacion'], style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(negocio['descripcion'] ?? 'Sin descripción disponible.',
                      style: TextStyle(color: Colors.grey[600])),
                  const Divider(height: 30),
                  const Text("Nuestra Carta", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // 3. Lista de Productos de ESTA tienda solamente
          StreamBuilder<List<Map<String, dynamic>>>(
            // FILTRO CLAVE: .eq('fk_negocio', negocio['id'])
            stream: Supabase.instance.client
                .from('productos')
                .stream(primaryKey: ['id'])
                .eq('fk_negocio', negocio['id']), 
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()));
              }

              final productos = snapshot.data!;

              if (productos.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text("\nNo hay productos disponibles")),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => CartaProducto(producto: productos[index]),
                    childCount: productos.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}