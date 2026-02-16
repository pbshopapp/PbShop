import 'package:flutter/material.dart';
import 'package:pbshop/pantallas/inicio_content.dart';
import 'package:pbshop/pantallas/info_page.dart';
import 'package:pbshop/pantallas/shops_page.dart';

class home_page extends StatefulWidget {
  const home_page({super.key});

  @override
  State<home_page> createState() => _HomePageState();
}

class _HomePageState extends State<home_page> {
  int _indiceActual = 0;

  final List<Widget> _vistas = [
    const InicioContent(), 
    const shops_page(), 
    const Center(child: Text("Pantalla de Pedidos/Historial")),
    const info_page(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _vistas[_indiceActual],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _indiceActual,
            onTap: (index) => setState(() => _indiceActual = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color.fromRGBO(0, 180, 195, 1),
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
              BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Explorar'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_checkout), activeIcon: Icon(Icons.shopping_cart), label: 'Pedidos'),
              BottomNavigationBarItem(icon: Icon(Icons.info_outline), activeIcon: Icon(Icons.info), label: 'Info'),
            ],
          ),
        ),
      ),
    );
  }
}