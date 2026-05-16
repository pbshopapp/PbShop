import 'package:flutter/material.dart';

class EncabezadoAnimado extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget? iconoAlternativo;
  final bool mostrarLogo;

  const EncabezadoAnimado({
    super.key,
    this.titulo = "Shop",
    this.subtitulo = "El aliado del parche pascualino.",
    this.iconoAlternativo,
    this.mostrarLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos el padding superior (Notch/Barra de estado)
    final double paddingSuperior = MediaQuery.of(context).padding.top;
    const Color colorInstitucional = Color.fromRGBO(0, 180, 195, 1);
    
    // Altura personalizada según el dispositivo (puedes subirla en PC si quieres)
    final double alturaExpandida = 220.0 + paddingSuperior;

    return SliverAppBar(
      expandedHeight: alturaExpandida,
      pinned: true,
      elevation: 0,
      // El toolbar debe ser al menos el padding + un tamaño cómodo para el logo pequeño
      toolbarHeight: 60 + paddingSuperior, 
      backgroundColor: colorInstitucional,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          double top = constraints.biggest.height;
          
          // Calculamos la opacidad de los textos basándonos en el scroll
          double opacity = ((top - (60 + paddingSuperior)) / (alturaExpandida - (60 + paddingSuperior))).clamp(0.0, 1.0);
          
          // El tamaño del logo ahora es relativo al ancho o alto, lo que sea menor (para PC)
          double anchoPantalla = MediaQuery.of(context).size.width;
          double baseSize = anchoPantalla > 600 ? 120 : top * 0.4; // Límite para PC
          
          double logoSize = (top > 100 + paddingSuperior) 
              ? baseSize.clamp(50.0, 100.0) 
              : 50.0;

          // La posición TOP ahora suma el paddingSuperior para no chocar con la cámara
          double posicionTop = (top > 100 + paddingSuperior) 
              ? (top * 0.2 + (paddingSuperior * 0.5)).clamp(paddingSuperior + 5, 80.0) 
              : paddingSuperior + 5;

          return Stack(
            alignment: Alignment.center,
            children: [
              // TEXTOS
              Opacity(
                opacity: opacity,
                child: FlexibleSpaceBar(
                  background: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 80 + paddingSuperior), 
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 26, 
                          fontWeight: FontWeight.w900
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          subtitulo,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70, 
                            fontSize: 14, 
                            fontStyle: FontStyle.italic
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // LOGO O ICONO (Flotante y Responsivo)
              Positioned(
                top: posicionTop,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: logoSize,
                  child: mostrarLogo 
                    ? Image.asset('recursos/imagenes/Pb-shop-logo.png', fit: BoxFit.contain)
                    : (iconoAlternativo ?? const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 40)),
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