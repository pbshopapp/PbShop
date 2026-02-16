import 'package:flutter/material.dart';

class EncabezadoAnimado extends StatelessWidget {
  const EncabezadoAnimado({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      toolbarHeight: 80,
      backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
      // Usamos flexibleSpace con un Stack para mover la imagen libremente
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          double top = constraints.biggest.height;
          
          // Calculamos el tamaño: cuando está expandido (250) mide 130
          // Cuando se encoge (80) mide 55.
          double logoSize = (top > 80) ? (top * 0.5).clamp(55.0, 100.0) : 55.0;
          
          // Calculamos la posición: mientras más pequeña la barra, más sube el logo
          double posicionTop = (top > 80) ? (top * 0.15).clamp(40.0, 80.0) : 40.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              // 1. Fondo con los textos
              FlexibleSpaceBar(
                background: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100), // Espacio para no chocar con el logo
                    const Text(
                      "Shop",
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "El aliado del parche pascualino.",
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              
              // 2. LA IMAGEN: Usamos Positioned para que flote arriba siempre
              Positioned(
                top: posicionTop, // Se mantiene cerca del tope
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  height: logoSize, // Aquí cambia el tamaño visualmente
                  child: Image.asset(
                    'recursos/imagenes/Pb-shop-logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
    );
  }
}