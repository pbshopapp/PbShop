import 'package:flutter/material.dart';
import 'package:pbshop/servicios/ObtenerDatosUser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _datosService = ObtenerDatosUser();
  String _nombreLocal = 'No ha iniciado sesión';
  String _telefonoLocal = '';

  @override
  void initState() {
    super.initState();
    _nombreLocal = widget.nombre;
    _telefonoLocal = widget.telefono;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) { // Verifica que el widget siga en pantalla
        setState(() {
          // Esto refresca la UI automáticamente en cualquier cambio de sesión
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant PerfilWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nombre != widget.nombre || oldWidget.telefono != widget.telefono) {
      setState(() {
        _nombreLocal = widget.nombre;
        _telefonoLocal = widget.telefono;
      });
    }
  }

  void _guardarCambio(String columna, String valor) async {
    bool exito = await _datosService.actualizarCampoPerfil(columna, valor);
    
    if (exito) {
      // 3. Actualizamos la variable local según lo que se cambió
      setState(() {
        if (columna == 'nombre') _nombreLocal = valor;
        if (columna == 'telefono') _telefonoLocal = valor;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${columna[0].toUpperCase()}${columna.substring(1)} actualizado")),
      );
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar los datos")),
      );
    }
  }

  void _mostrarDialogoCambioPassword() {
    // Necesitamos dos controladores, uno para cada campo
    TextEditingController pass1Controller = TextEditingController();
    TextEditingController pass2Controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Cambiar Contraseña"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pass1Controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Nueva Contraseña",
                  hintText: "Mínimo 6 caracteres",
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: pass2Controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirmar Contraseña",
                  hintText: "Repite la contraseña",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                String p1 = pass1Controller.text.trim();
                String p2 = pass2Controller.text.trim();

                // 1. Validación de coincidencia
                if (p1 != p2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Las contraseñas no coinciden")),
                  );
                  return;
                }

                // 2. Validación de longitud
                if (p1.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Debe tener al menos 6 caracteres")),
                  );
                  return;
                }

                // 3. Ejecución del cambio
                bool exito = await _datosService.cambiarContrasenaAuth(p1);
                
                if (exito) {
                  Navigator.pop(context); // Cerramos el diálogo solo si hubo éxito
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Contraseña cambiada exitosamente")),
                  );
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
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
                        _nombreLocal,
                        Icons.person,
                        () => _mostrarDialogoEdicion("Nombre", widget.nombre, (nuevo) => _guardarCambio("nombre", nuevo)),
                      ),
                      const Divider(),
                      _datoConBoton(
                        "Teléfono", 
                        _verTelefono ? _telefonoLocal : "********", 
                        _verTelefono ? Icons.visibility_off : Icons.visibility,
                        () => setState(() => _verTelefono = !_verTelefono),
                        isToggle: true,
                        onEdit: () => _mostrarDialogoEdicion("Teléfono", _telefonoLocal, (nuevo) => _guardarCambio("telefono", nuevo)),
                        
                      ),
                      const Divider(),
                      _datoConBoton(
                        "Contraseña", 
                        "********", 
                        Icons.lock_outline, 
                        () => _mostrarDialogoCambioPassword(), // Llamamos a la nueva función de doble campo
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