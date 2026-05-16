import 'package:flutter/material.dart';

class BuscadorWidget extends StatelessWidget {
  final Function(String) onChanged;
  final VoidCallback onFilterPressed; // Nuevo callback para la acción de filtrar

  const BuscadorWidget({
    super.key, 
    required this.onChanged,
    required this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    const Color colorInstitucional = Color.fromRGBO(0, 180, 195, 1);
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = esOscuro ? const Color(0xFF1E1E1E) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            // Campo de texto expandido
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(esOscuro ? 0.3 : 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: onChanged,
                  cursorColor: colorInstitucional,
                  style: TextStyle(
                    fontSize: 15,
                    color: esOscuro ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: "Buscar en PB-Shop...",
                    hintStyle: TextStyle(
                      color: esOscuro ? Colors.white54 : Colors.grey[500],
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: colorInstitucional,
                      size: 22,
                    ),
                    filled: true,
                    fillColor: colorFondo,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: colorInstitucional.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12), // Espaciado entre buscador y botón
            
            // Botón de Filtrar Estilo Minimalista
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(esOscuro ? 0.3 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: colorFondo,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onFilterPressed,
                  borderRadius: BorderRadius.circular(20),
                  splashColor: colorInstitucional.withOpacity(0.1),
                  highlightColor: colorInstitucional.withOpacity(0.05),
                  child: Container(
                    height: 50, // Alineado con la altura promedio del TextField
                    width: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.tune_rounded, // Icono moderno de filtros/ajustes
                      color: colorInstitucional,
                      size: 22,
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
}