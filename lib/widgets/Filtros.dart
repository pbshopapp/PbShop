import 'package:flutter/material.dart';

class FiltrosModal extends StatefulWidget {
  final List<Map<String, dynamic>> categorias;
  final String? categoriaSeleccionada;
  final RangeValues rangoPreciosSeleccionado;
  final RangeValues rangoMaximoPrecios;
  final Function(String?, RangeValues) onAplicarFiltros;

  const FiltrosModal({
    super.key,
    required this.categorias,
    required this.categoriaSeleccionada,
    required this.rangoPreciosSeleccionado,
    required this.rangoMaximoPrecios,
    required this.onAplicarFiltros,
  });

  // Método estático auxiliar para mostrar el modal fácilmente desde cualquier pantalla
  static void mostrar(
    BuildContext context, {
    required List<Map<String, dynamic>> categorias,
    required String? categoriaSeleccionada,
    required RangeValues rangoPreciosSeleccionado,
    required RangeValues rangoMaximoPrecios,
    required Function(String?, RangeValues) onAplicarFiltros,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FiltrosModal(
        categorias: categorias,
        categoriaSeleccionada: categoriaSeleccionada,
        rangoPreciosSeleccionado: rangoPreciosSeleccionado,
        rangoMaximoPrecios: rangoMaximoPrecios,
        onAplicarFiltros: onAplicarFiltros,
      ),
    );
  }

  @override
  State<FiltrosModal> createState() => _FiltrosModalState();
}

class _FiltrosModalState extends State<FiltrosModal> {
  static const Color colorPB = Color.fromRGBO(0, 180, 195, 1);
  
  String? _catTemporal;
  late RangeValues _preciosTemporales;

  @override
  void initState() {
    super.initState();
    _catTemporal = widget.categoriaSeleccionada;
    _preciosTemporales = widget.rangoPreciosSeleccionado;
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = esOscuro ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra superior de arrastre / Indicador visual
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: esOscuro ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Encabezado del Modal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Filtrar Búsqueda",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _catTemporal = null;
                    _preciosTemporales = widget.rangoMaximoPrecios;
                  });
                },
                child: const Text("Limpiar", style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
          const Divider(height: 30),

          // --- SECCIÓN 1: CATEGORÍAS ---
          const Text(
            "Categorías",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.categorias.map((cat) {
              final String idStr = cat['id'].toString();
              final bool estaSeleccionado = _catTemporal == idStr;
              return ChoiceChip(
                label: Text(cat['nombre']),
                selected: estaSeleccionado,
                selectedColor: colorPB.withOpacity(0.2),
                checkmarkColor: colorPB,
                labelStyle: TextStyle(
                  color: estaSeleccionado 
                      ? colorPB 
                      : (esOscuro ? Colors.white70 : Colors.black87),
                  fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: esOscuro ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                side: BorderSide(
                  color: estaSeleccionado ? colorPB : Colors.transparent,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (bool seleccionado) {
                  setState(() {
                    _catTemporal = seleccionado ? idStr : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 30),

          // --- SECCIÓN 2: RANGO DE PRECIOS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Rango de Precios",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                "\$${_preciosTemporales.start.round()} - \$${_preciosTemporales.end.round()}",
                style: const TextStyle(color: colorPB, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 5),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colorPB,
              inactiveTrackColor: colorPB.withOpacity(0.2),
              thumbColor: colorPB,
              overlayColor: colorPB.withOpacity(0.1),
              valueIndicatorColor: colorPB,
            ),
            child: RangeSlider(
              values: _preciosTemporales,
              min: widget.rangoMaximoPrecios.start,
              max: widget.rangoMaximoPrecios.end,
              divisions: 50,
              labels: RangeLabels(
                "\$${_preciosTemporales.start.round()}",
                "\$${_preciosTemporales.end.round()}",
              ),
              onChanged: (RangeValues valores) {
                setState(() {
                  _preciosTemporales = valores;
                });
              },
            ),
          ),
          const SizedBox(height: 30),

          // --- BOTÓN DE APLICAR ---
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                widget.onAplicarFiltros(_catTemporal, _preciosTemporales);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPB,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text(
                "Aplicar Filtros",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}