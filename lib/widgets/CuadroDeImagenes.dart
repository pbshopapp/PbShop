import 'package:flutter/material.dart';

class CuadroDeImagenes extends StatefulWidget {
  final List<String> urls;
  final bool mostrarPuntos;

  const CuadroDeImagenes({
    super.key,
    required this.urls,
    this.mostrarPuntos = true,
  });

  @override
  State<CuadroDeImagenes> createState() => _CuadroDeImagenesState();
}

class _CuadroDeImagenesState extends State<CuadroDeImagenes> {
  final PageController _controller = PageController();
  int _paginaActual = 0;
  bool _isHovering = false; // Controla si el mouse está sobre la imagen

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40)),
      );
    }

    return MouseRegion(
      // Detecta cuando el puntero entra o sale (Solo funcional en Web/Desktop)
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: ClipRRect(
        // REDONDEO SOLO SUPERIOR
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)), 
        child: Stack(
          children: [
            // 1. Carrusel
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
                );
              },
            ),

            // 2. Contador (Siempre visible o puedes envolverlo en AnimatedOpacity)
            Positioned(
              top: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_paginaActual + 1}/${widget.urls.length}",
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // 3. Flechas - Solo aparecen si es PC (Hover) y hay más de 1 imagen
            if (widget.urls.length > 1)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isHovering ? 1.0 : 0.0, // Aparecen suavemente al pasar el mouse
                child: Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBotonPC(Icons.chevron_left_rounded, () {
                        _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      }),
                      _buildBotonPC(Icons.chevron_right_rounded, () {
                        _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      }),
                    ],
                  ),
                ),
              ),

            // 4. Indicador de Puntos
            if (widget.mostrarPuntos && widget.urls.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.urls.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 5,
                      width: _paginaActual == index ? 15 : 5,
                      decoration: BoxDecoration(
                        color: _paginaActual == index ? Colors.white : Colors.white60,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonPC(IconData icono, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: IconButton(
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black26,
          foregroundColor: Colors.white,
          hoverColor: Colors.black45,
        ),
        icon: Icon(icono, size: 30),
      ),
    );
  }
}