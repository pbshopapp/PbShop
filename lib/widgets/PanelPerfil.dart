import 'package:flutter/material.dart';
import 'package:pbshop/servicios/ObtenerDatosUser.dart';

class PerfilWidget extends StatefulWidget {
  final String nombre;
  final String telefono;
  final String contrasena;
  final String avatarUrl;
  final VoidCallback onActualizar;

  const PerfilWidget({
    super.key,
    required this.nombre,
    required this.telefono,
    required this.contrasena,
    required this.avatarUrl,
    required this.onActualizar,
  });

  @override
  State<PerfilWidget> createState() => _PerfilWidgetState();
}

class _PerfilWidgetState extends State<PerfilWidget> {
  bool _verTelefono = false;
  final _datosService = ObtenerDatosUser();
  late String _nombreLocal;
  late String _telefonoLocal;

  @override
  void initState() {
    super.initState();
    _nombreLocal = widget.nombre;
    _telefonoLocal = widget.telefono;
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

  // --- LÓGICA DE GUARDADO (Tuya) ---
  void _guardarCambio(String columna, String valor) async {
    bool exito = await _datosService.actualizarCampoPerfil(columna, valor);
    if (exito) {
      setState(() {
        if (columna == 'nombre') _nombreLocal = valor;
        if (columna == 'telefono') _telefonoLocal = valor;
      });
      widget.onActualizar(); // Notificar a la pantalla para recargar datos

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${columna[0].toUpperCase()}${columna.substring(1)} actualizado")),
      );
    }
  }

  // --- UI MEJORADA ESTILO DIDI ---
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // FOTO DE PERFIL
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: NetworkImage(widget.avatarUrl),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => print("Cambiar foto"),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(0, 180, 195, 1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            
            // CAMPOS DE DATOS
            _itemDato(
              "Nombre", 
              _nombreLocal, 
              Icons.person_outline, 
              () => _mostrarDialogoEdicion("Nombre", _nombreLocal, (n) => _guardarCambio("nombre", n))
            ),
            const Divider(height: 30),
            _itemDato(
              "Teléfono", 
              _verTelefono ? _telefonoLocal : "********", 
              _verTelefono ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
              () => setState(() => _verTelefono = !_verTelefono),
              onEdit: () => _mostrarDialogoEdicion("Teléfono", _telefonoLocal, (t) => _guardarCambio("telefono", t)),
            ),
            const Divider(height: 30),
            _itemDato(
              "Contraseña", 
              "********", 
              Icons.lock_reset_outlined, 
              () => _mostrarDialogoCambioPassword()
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemDato(String titulo, String valor, IconData icono, VoidCallback onTap, {VoidCallback? onEdit}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (onEdit != null) // Caso especial para teléfono (Ver y Editar)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Color.fromRGBO(0, 180, 195, 1)),
            onPressed: onEdit,
          ),
        IconButton(
          icon: Icon(icono, size: 22, color: Colors.grey[400]),
          onPressed: onTap,
        ),
      ],
    );
  }

  // --- DIÁLOGOS (Mantengo tu lógica intacta) ---
  void _mostrarDialogoEdicion(String titulo, String valorActual, Function(String) onGuardar) {
    TextEditingController controller = TextEditingController(text: valorActual);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Editar $titulo"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: "Nuevo $titulo", border: const UnderlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(0, 180, 195, 1)),
            onPressed: () {
              onGuardar(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCambioPassword() {
    TextEditingController pass1Controller = TextEditingController();
    TextEditingController pass2Controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cambiar Contraseña"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: pass1Controller, obscureText: true, decoration: const InputDecoration(labelText: "Nueva Contraseña")),
            const SizedBox(height: 10),
            TextField(controller: pass2Controller, obscureText: true, decoration: const InputDecoration(labelText: "Confirmar")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(0, 180, 195, 1)),
            onPressed: () async {
              if (pass1Controller.text == pass2Controller.text && pass1Controller.text.length >= 6) {
                bool exito = await _datosService.cambiarContrasenaAuth(pass1Controller.text.trim());
                if (exito) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contraseña actualizada")));
                }
              }
            },
            child: const Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}