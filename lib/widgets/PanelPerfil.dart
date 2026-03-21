import 'package:flutter/material.dart';
import 'package:pbshop/servicios/ObtenerDatosUser.dart';

class PerfilWidget extends StatefulWidget {
  final String nombre;
  final String telefono;
  final String contrasena;
  final String avatarUrl;

  const PerfilWidget({
    super.key,
    required this.nombre,
    required this.telefono,
    required this.contrasena,
    required this.avatarUrl,
  });

  @override
  State<PerfilWidget> createState() => _PerfilWidgetState();
}

class _PerfilWidgetState extends State<PerfilWidget> {
  // Estados para visibilidad
  bool _verTelefono = false;
  bool _verContrasena = false;
  final _datosService = ObtenerDatosUser();

  void _guardarCambio(String columna, String valor) async {
    bool exito = await _datosService.actualizarCampoPerfil(columna, valor);
    
    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$columna actualizado con éxito")),
      );
      // Aquí podrías disparar un setState o un callback para refrescar la UI
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar los datos")),
      );
    }
  }
  // Función para mostrar un diálogo de edición
  void _mostrarDialogoEdicion(String titulo, String valorActual, Function(String) onGuardar) {
    TextEditingController controller = TextEditingController(text: valorActual);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Editar $titulo"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Nuevo $titulo"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              onGuardar(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Foto de perfil con Stack
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: NetworkImage(widget.avatarUrl),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => print("Cambiar foto de perfil"),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color.fromRGBO(0, 180, 195, 1),
                          child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Datos del usuario
                Expanded(
                  child: Column(
                    children: [
                      _datoConBoton(
                        "Nombre", 
                        widget.nombre, 
                        Icons.person,
                        () => _mostrarDialogoEdicion("Nombre", widget.nombre, (nuevo) => _guardarCambio("nombre", nuevo)),
                      ),
                      const Divider(),
                      _datoConBoton(
                        "Teléfono", 
                        _verTelefono ? widget.telefono : "********", 
                        _verTelefono ? Icons.visibility_off : Icons.visibility,
                        () => setState(() => _verTelefono = !_verTelefono),
                        isToggle: true,
                        onEdit: () => _mostrarDialogoEdicion("Teléfono", widget.telefono, (nuevo) => _guardarCambio("telefono", nuevo)),
                      ),
                      const Divider(),
                      _datoConBoton(
                        "Contraseña", 
                        _verContrasena ? widget.contrasena : "********", 
                        _verContrasena ? Icons.visibility_off : Icons.visibility,
                        () => setState(() => _verContrasena = !_verContrasena),
                        isToggle: true,
                        onEdit: () => _mostrarDialogoEdicion("Contraseña", widget.contrasena, (nuevo) => _guardarCambio("contrasena", nuevo)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _datoConBoton(String titulo, String valor, IconData iconoAccion, VoidCallback onIconPressed, {bool isToggle = false, VoidCallback? onEdit}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
              Text(valor, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Row(
          children: [
            // Botón de Ver/Ocultar (si aplica)
            IconButton(
              icon: Icon(iconoAccion, size: 20, color: Colors.blueGrey),
              onPressed: onIconPressed,
            ),
            // Botón de Editar (si es un campo con toggle, mostramos también el de editar)
            if (isToggle)
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Color.fromRGBO(0, 180, 195, 1)),
                onPressed: onEdit,
              )
            else if (!isToggle) // Si no es toggle, el botón principal es editar
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Color.fromRGBO(0, 180, 195, 1)),
                onPressed: onIconPressed,
              ),
          ],
        ),
      ],
    );
  }
}