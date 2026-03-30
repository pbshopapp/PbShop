import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/widgets/CartaProducto.dart';
import 'package:pbshop/widgets/BarraEmpresas.dart';
import 'package:pbshop/widgets/EncabezadoAnimado.dart';
import 'package:pbshop/widgets/BuscadorWidget.dart';

class InicioContent extends StatefulWidget {
  const InicioContent({super.key});

  @override
  State<InicioContent> createState() => _InicioContentState();
}

class _InicioContentState extends State<InicioContent> {
  String textoBusqueda = "";

  @override
  Widget build(BuildContext context) {
    // Definimos el stream de productos
    final Stream<List<Map<String, dynamic>>> productosStream = Supabase.instance.client
        .from('v_productos_con_rating')
        .stream(primaryKey: ['id']);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const EncabezadoAnimado(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                BuscadorWidget(
                  onChanged: (valor) {
                    setState(() {
                      textoBusqueda = valor;
                    });
                  },
                ),
                const BarraEmpresas(),
              ],
            ),
          ),
          
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: productosStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(50.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              List<Map<String, dynamic>> productos = snapshot.data ?? [];

              // Filtro de búsqueda local
              if (textoBusqueda.isNotEmpty) {
                productos = productos.where((item) {
                  final nombre = item['nombre'].toString().toLowerCase();
                  final consulta = textoBusqueda.toLowerCase();
                  return nombre.contains(consulta);
                }).toList();
              } else {
                productos.shuffle(); // Aleatoriedad si no hay búsqueda
              }

              if (productos.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text(
                        "No se encontraron productos",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }

              // GRID DINÁMICO Y RESPONSIVO
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200, // Cada tarjeta no medirá más de 200px de ancho
                    mainAxisSpacing: 12,    // Espacio vertical entre tarjetas
                    crossAxisSpacing: 12,   // Espacio horizontal entre tarjetas
                    mainAxisExtent: 260,    // ALTURA FIJA: Evita que el precio se corte
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return CartaProducto(producto: productos[index]);
                    },
                    childCount: productos.length,
                  ),
                ),
              );
            },
          ),
          // Espacio extra al final para que el último producto no quede pegado al borde
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}