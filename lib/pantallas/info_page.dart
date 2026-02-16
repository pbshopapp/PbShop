import 'package:flutter/material.dart';
import 'package:pbshop/pantallas/documentation_page.dart';
import 'package:pbshop/pantallas/help_page.dart';

class info_page extends StatelessWidget {
  const info_page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cuenta")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("PB Shop", 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromRGBO(0, 180, 195, 1))),
          const SizedBox(height: 10),
          const Text("Proyecto de ecosistema digital para el Pascual Bravo."),
          const Divider(height: 40),
          
          _itemFinanciero("Inversión", "Detalles del proyecto pascualino", Icons.trending_up, Colors.blue),
          
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const help_page()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 30),
            ),
            icon: const Icon(Icons.description),
            label: const Text("Ayuda y contacto"),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const documentation_page()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 30),
            ),
            icon: const Icon(Icons.description),
            label: const Text("Terminos y condiciones"),
          ),
        ],
      ),
    );
  }

  Widget _itemFinanciero(String titulo, String subtitulo, IconData icono, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icono, color: color)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitulo),
      ),
    );
  }
}