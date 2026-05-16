import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/widgets/CartaProducto.dart';

class DetailsNegPage extends StatelessWidget {
  final Map<String, dynamic> negocio;

  const DetailsNegPage({super.key, required this.negocio});

  final Color colorPB = const Color.fromRGBO(0, 180, 195, 1);

  Future<List<Map<String, dynamic>>> _obtenerTodasLasResenas() async {
    try {
      final idBusqueda = negocio['id'];
      if (idBusqueda == null) return [];
      final List<dynamic> res = await Supabase.instance.client
          .from('resenas')
          .select()
          .eq('fk_negocio', idBusqueda);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  void _mostrarPanelResenas(BuildContext context, List<Map<String, dynamic>> resenas) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(10))),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("Reseñas de la comunidad", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: resenas.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final r = resenas[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: colorPB.withOpacity(0.1),
                        child: Text("${r['puntuacion']}", style: TextStyle(color: colorPB, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(r['comentario'] ?? "Sin comentario", style: const TextStyle(fontSize: 14)),
                      subtitle: const Text("Estudiante Pascualino", style: TextStyle(fontSize: 11)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: colorPB,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(negocio['nombre'],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, shadows: [Shadow(blurRadius: 10, color: Colors.black54)])),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  negocio['imagen_url'] != null ? Image.network(negocio['imagen_url'], fit: BoxFit.cover) : Container(color: colorPB),
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
                      Expanded(child: Text(negocio['ubicacion'] ?? 'Ubicación no disponible', style: const TextStyle(fontSize: 16))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _obtenerTodasLasResenas(),
                    builder: (context, snapshot) {
                      final resenas = snapshot.data ?? [];
                      double promedio = 0;
                      if (resenas.isNotEmpty) {
                        promedio = resenas.fold(0.0, (prev, e) => prev + (e['puntuacion'] ?? 0)) / resenas.length;
                      }
                      return Row(
                        children: [
                          Icon(Icons.star_rounded, color: promedio > 0 ? Colors.amber : Colors.grey, size: 22),
                          const SizedBox(width: 5),
                          Text(promedio > 0 ? promedio.toStringAsFixed(1) : "Nuevo", style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (resenas.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: () => _mostrarPanelResenas(context, resenas),
                              child: Text("Ver ${resenas.length} comentarios", style: TextStyle(color: colorPB, decoration: TextDecoration.underline, fontSize: 13)),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(negocio['descripcion'] ?? '', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 14)),
                  const Divider(height: 40),
                  const Text("Nuestra Carta", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client.from('productos').stream(primaryKey: ['id']).eq('fk_negocio', negocio['id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              final productos = snapshot.data ?? [];
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 280,
                  ),
                  delegate: SliverChildBuilderDelegate((context, i) => CartaProducto(producto: productos[i]), childCount: productos.length),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}