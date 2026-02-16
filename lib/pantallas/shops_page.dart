import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/widgets/CartaNegocio.dart';

class shops_page extends StatelessWidget {
  const shops_page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tiendas de la U"),
        backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Consultamos la tabla 'negocios'
        stream: Supabase.instance.client.from('negocios').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay tiendas registradas aún."));
          }

          final tiendas = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Dos columnas
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85, // Ajusta la altura de los recuadros
            ),
            itemCount: tiendas.length,
            itemBuilder: (context, index) {
              return CartaNegocio(negocio: tiendas[index]);
            },
          );
        },
      ),
    );
  }
}