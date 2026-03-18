import 'package:flutter/material.dart';

class CuadroDeImagenes extends StatefulWidget {
  final List<String> urls;
  final bool mostrarFlechas; // Controla las flechas laterales
  final bool mostrarPuntos;  // Controla los puntos indicadores abajo

  const CuadroDeImagenes({
    super.key,
    required this.urls,
    this.mostrarFlechas = true, // Por defecto activo para la página de producto
    this.mostrarPuntos = true,  // Por defecto activo
  });

  @override
  State<CuadroDeImagenes> createState() => _CuadroDeImagenesState();
}

class _CuadroDeImagenesState extends State<CuadroDeImagenes> {
  final PageController _controller = PageController();
  int _paginaActual = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return const Center(child: Icon(Icons.image_not_supported, color: Colors.grey));
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // 1. Visor de imágenes con gestos táctiles (Swipe)
        PageView.builder(
          controller: _controller,
          onPageChanged: (index) => setState(() => _paginaActual = index),
          itemCount: widget.urls.length,
          itemBuilder: (context, index) {
            return Image.network(
              widget.urls[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            );
          },
        ),

        // 2. Botones de navegación (Flechas) - Solo si se solicita y hay más de 1 imagen
        if (widget.mostrarFlechas && widget.urls.length > 1)
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBotonNavegacion(Icons.chevron_left, () {
                  _controller.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                }),
                _buildBotonNavegacion(Icons.chevron_right, () {
                  _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                }),
              ],
            ),
          ),

        // 3. Indicador de puntos (Dots) - Solo si se solicita y hay más de 1 imagen
        if (widget.mostrarPuntos && widget.urls.length > 1)
          Positioned(
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.urls.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _paginaActual == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _paginaActual == index ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 2)
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Widget privado para crear los botones laterales
  Widget _buildBotonNavegacion(IconData icono, VoidCallback alPresionar) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: alPresionar,
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}