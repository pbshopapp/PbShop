import 'package:flutter/material.dart';

class BuscadorWidget extends StatelessWidget {
  const BuscadorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: '¿Qué buscas hoy? (Empanadas, Cafe...)',
          prefixIcon: const Icon(Icons.search, color: Color.fromRGBO(0, 180, 195, 1)),
          // Bordes redondeados y estilizados
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none, // Quitamos el borde negro por defecto
          ),
          filled: true,
          fillColor: Colors.grey[200], // Un fondo gris suave
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }
}