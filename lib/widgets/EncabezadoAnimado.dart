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
    final double paddingSuperior = MediaQuery.of(context).padding.top;
    const Color colorInstitucional = Color.fromRGBO(0, 180, 195, 1);
    
    // Altura cómoda que da espacio al logo grande y textos sin colapsar
    final double alturaExpandida = 240.0 + paddingSuperior;

    return SliverAppBar(
      expandedHeight: alturaExpandida,
      pinned: true,
      elevation: 0,
      toolbarHeight: 60 + paddingSuperior, 
      backgroundColor: colorInstitucional,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          double top = constraints.biggest.height;
          double limiteToolbar = 60 + paddingSuperior;
          
          // Calculamos la opacidad de los elementos basados en el scroll
          double opacity = ((top - limiteToolbar) / (alturaExpandida - limiteToolbar)).clamp(0.0, 1.0);
          
          // Tamaño dinámico del logo (Más grande cuando está expandido, se reduce al hacer scroll)
          double logoSize = opacity > 0.2 ? (90 * opacity).clamp(40.0, 90.0) : 40.0;

          return FlexibleSpaceBar(
            titlePadding: EdgeInsets.zero,
            centerTitle: true,
            // 1. Cuando la barra colapsa, este es el widget que se queda fijo en el toolbar
            title: opacity < 0.15
                ? Container(
                    padding: EdgeInsets.only(top: paddingSuperior),
                    height: 50,
                    child: mostrarLogo
                        ? Image.asset('recursos/imagenes/Pb-shop-logo.png', fit: BoxFit.contain)
                        : (iconoAlternativo ?? const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 24)),
                  )
                : null,
            // 2. Cuando la barra está expandida (Vista principal), se muestra la estructura limpia
            background: Opacity(
              opacity: opacity,
              child: Padding(
                padding: EdgeInsets.only(top: paddingSuperior + 20, bottom: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO (Integrado a la columna para que empuje los textos dinámicamente)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      height: logoSize,
                      child: mostrarLogo
                          ? Image.asset('recursos/imagenes/Pb-shop-logo.png', fit: BoxFit.contain)
                          : (iconoAlternativo ?? const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 50)),
                    ),
                    const SizedBox(height: 10),
                    // TÍTULO
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 26, 
                        fontWeight: FontWeight.w900
                      ),
                    ),
                    const SizedBox(height: 4),
                    // SUBTÍTULO
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      key: UniqueKey(), // Fuerza el redibujado correcto en cambios de tamaño
                      child: Text(
                        subtitulo,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70, 
                          fontSize: 13, 
                          fontStyle: FontStyle.italic
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
    );
  }
}