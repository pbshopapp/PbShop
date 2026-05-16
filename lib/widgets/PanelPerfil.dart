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

  // Color institucional
  final Color colorPB = const Color.fromRGBO(0, 180, 195, 1);

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

  void _guardarCambio(String columna, String valor) async {
    bool exito = await _datosService.actualizarCampoPerfil(columna, valor);
    if (exito) {
      if (mounted) {
        setState(() {
          if (columna == 'nombre') _nombreLocal = valor;
          if (columna == 'telefono') _telefonoLocal = valor;
        });
        widget.onActualizar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${columna[0].toUpperCase()}${columna.substring(1)} actualizado")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
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
                  backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                  backgroundImage: NetworkImage(widget.avatarUrl),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => debugPrint("Cambiar foto"),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorPB,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, width: 2),
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
              () => _mostrarDialogoEdicion(context, "Nombre", _nombreLocal, (n) => _guardarCambio("nombre", n), isDark),
              isDark
            ),
            Divider(height: 30, color: isDark ? Colors.white10 : Colors.grey[200]),
            _itemDato(
              "Teléfono", 
              _verTelefono ? _telefonoLocal : "********", 
              _verTelefono ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
              () => setState(() => _verTelefono = !_verTelefono),
              isDark,
              onEdit: () => _mostrarDialogoEdicion(context, "Teléfono", _telefonoLocal, (t) => _guardarCambio("telefono", t), isDark),
            ),
            Divider(height: 30, color: isDark ? Colors.white10 : Colors.grey[200]),
            _itemDato(
              "Contraseña", 
              "********", 
              Icons.lock_reset_outlined, 
              () => _mostrarDialogoCambioPassword(context, isDark),
              isDark
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemDato(String titulo, String valor, IconData icono, VoidCallback onTap, bool isDark, {VoidCallback? onEdit}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[500], fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: colorPB),
            onPressed: onEdit,
          ),
        IconButton(
          icon: Icon(icono, size: 22, color: isDark ? Colors.white38 : Colors.grey[400]),
          onPressed: onTap,
        ),
      ],
    );
  }

  void _mostrarDialogoEdicion(BuildContext context, String titulo, String valorActual, Function(String) onGuardar, bool isDark) {
    TextEditingController controller = TextEditingController(text: valorActual);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Editar $titulo", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: "Nuevo $titulo",
            hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar", style: TextStyle(color: isDark ? Colors.white38 : Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorPB),
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

  void _mostrarDialogoCambioPassword(BuildContext context, bool isDark) {
    TextEditingController pass1Controller = TextEditingController();
    TextEditingController pass2Controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Cambiar Contraseña", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pass1Controller, 
              obscureText: true, 
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Nueva Contraseña",
                labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
              )
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pass2Controller, 
              obscureText: true, 
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Confirmar",
                labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
              )
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar", style: TextStyle(color: isDark ? Colors.white38 : Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorPB),
            onPressed: () async {
              if (pass1Controller.text == pass2Controller.text && pass1Controller.text.length >= 6) {
                bool exito = await _datosService.cambiarContrasenaAuth(pass1Controller.text.trim());
                if (exito && mounted) {
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