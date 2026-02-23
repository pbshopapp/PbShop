import 'package:flutter/material.dart';

class PerfilWidget extends StatelessWidget {
  final String nombre;
  final String telefono;
  final String contrasena;
  final String avatarUrl;

  const PerfilWidget({
    Key? key,
    required this.nombre,
    required this.telefono,
    required this.contrasena,
    required this.avatarUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Foto de perfil con botón de editar
            Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () {
                      // Acción para editar foto
                    },
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.edit, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),

            // Datos del usuario
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _datoConBoton("Nombre", nombre, () {
                    // Acción para editar nombre
                  }),
                  const SizedBox(height: 10),
                  _datoConBoton("Teléfono", "********", () {
                    // Acción para editar teléfono
                  }),
                  const SizedBox(height: 10),
                  _datoConBoton("Contraseña", "********", () {
                    // Acción para editar contraseña
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datoConBoton(String titulo, String valor, VoidCallback onEdit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(valor),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
          onPressed: onEdit,
        ),
      ],
    );
  }
}