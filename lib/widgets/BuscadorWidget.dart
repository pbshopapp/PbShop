import 'package:flutter/material.dart';

class BuscadorWidget extends StatelessWidget {
  final Function(String) onChanged; // Agregamos la definición

  const BuscadorWidget({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: onChanged, // Conectamos con el TextField
        decoration: InputDecoration(
          hintText: "Buscar productos...",
          prefixIcon: const Icon(Icons.search, color: Color.fromRGBO(0, 180, 195, 1)),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}