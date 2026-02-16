import 'package:flutter/material.dart';
class BarraEmpresas extends StatelessWidget {
  const BarraEmpresas({super.key});

  // Datos de ejemplo
  final List<Map<String, dynamic>> empresas = const [
    {'nombre': 'Papelería B4', 'icon': Icons.print},
    {'nombre': 'Café B8', 'icon': Icons.local_cafe},
    {'nombre': 'Aurora B6', 'icon': Icons.local_cafe},
    {'nombre': 'Jugos B26', 'icon': Icons.local_drink},
    {'nombre': 'Cafeteria b13', 'icon': Icons.fastfood},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: empresas.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green[100],
                  child: Icon(empresas[index]['icon'], color: Colors.green[900]),
                ),
                const SizedBox(height: 8),
                Text(
                  empresas[index]['nombre'],
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}