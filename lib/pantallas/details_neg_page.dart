import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/widgets/CartaProducto.dart';

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
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                negocio['nombre'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
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
                      Expanded(
                        child: Text(
                          negocio['ubicacion'] ?? 'Ubicación no disponible',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    negocio['descripcion'] ?? 'Sin descripción disponible.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const Divider(height: 40, thickness: 1),
                  const Text(
                    "Nuestra Carta",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // 3. Lista de Productos Responsiva
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('productos')
                .stream(primaryKey: ['id'])
                .eq('fk_negocio', negocio['id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              final productos = snapshot.data ?? [];

              if (productos.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text(
                        "Este negocio aún no tiene productos registrados",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200, // Ajuste automático de columnas
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 260, // Altura fija para evitar cortes
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => CartaProducto(producto: productos[index]),
                    childCount: productos.length,
                  ),
                ),
              );
            },
          ),
          // Espaciado final para scroll cómodo
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}