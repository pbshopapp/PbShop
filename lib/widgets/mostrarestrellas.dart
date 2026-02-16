import 'package:flutter/material.dart';

Widget mostrarEstrellas(int puntuacion) {
  return Row(
    children: List.generate(5, (index) {
      return Icon(
        index < puntuacion ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 20,
      );
    }),
  );
}