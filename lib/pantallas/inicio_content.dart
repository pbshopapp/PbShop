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
    // Pedimos el stream completo de la vista.
    final Stream<List<Map<String, dynamic>>> productosStream = Supabase.instance.client
        .from('v_productos_con_rating')
        .stream(primaryKey: ['id']);

    // SOLUCIÓN: Agregamos un Scaffold para proporcionar el contexto de Material Design
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
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              List<Map<String, dynamic>> productos = snapshot.data ?? [];

              if (textoBusqueda.isNotEmpty) {
                productos = productos.where((item) {
                  final nombre = item['nombre'].toString().toLowerCase();
                  final consulta = textoBusqueda.toLowerCase();
                  return nombre.contains(consulta);
                }).toList();
              } else {
                productos.shuffle();
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
                      return CartaProducto(producto: productos[index]);
                    },
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