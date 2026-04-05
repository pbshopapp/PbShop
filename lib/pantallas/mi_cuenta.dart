import 'package:flutter/material.dart';
import 'package:pbshop/widgets/widgetsInfo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/servicios/ObtenerDatosUser.dart';

import 'package:pbshop/widgets/PanelPerfil.dart';
class MiCuentaPage extends StatefulWidget {
  const MiCuentaPage({super.key});

  @override
  State<MiCuentaPage> createState() => _MiCuentaPageState();
}

class _MiCuentaPageState extends State<MiCuentaPage> {
  final _supabase = Supabase.instance.client;
  final _passController = TextEditingController();
  bool _isLoading = false;
  String nombre = "Usuario no registrado";
  String telefono = "********";
  String avatarUrl = "https://via.placeholder.com/150";
  // La contraseña no la mostramos por seguridad en este diseño, pero la cargamos
  String contrasena = "********";

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

    Future<void> _cargarDatos() async {
    try {
      final obtenerDatosUser = ObtenerDatosUser();
      final perfil = await obtenerDatosUser.getDatosUsuario();
      if (!mounted) return;
      setState(() {
        nombre = perfil.name;
        telefono = perfil.phone;
        contrasena = perfil.password;
        avatarUrl = perfil.avatarUrl;
      });
    } catch (e) {
      print("Error cargando perfil: $e");
    }
  }



  Future<void> _eliminarCuenta() async {
    setState(() => _isLoading = true);
    try {
      final email = _supabase.auth.currentUser?.email;
      
      // 1. Re-autenticar al usuario para confirmar que sabe su contraseña
      await _supabase.auth.signInWithPassword(
        email: email!,
        password: _passController.text,
      );

      // 2. Llamar a la Edge Function para borrarlo de Auth
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.functions.invoke(
        'delete-user',
        body: {'userId': userId},
      );

      // 3. Cerrar sesión y mandar al login
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cuenta eliminada correctamente")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Contraseña incorrecta o fallo de red")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogoConfirmacion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar cuenta?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Esta acción es irreversible. Ingresa tu contraseña para confirmar:"),
            const SizedBox(height: 15),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Contraseña",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _isLoading ? null : () {
              Navigator.pop(context);
              _eliminarCuenta();
            },
            child: const Text("ELIMINAR MI CUENTA", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Cuenta")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Reemplazamos el ListTile genérico por tu widget personalizado
            PerfilWidget(
              nombre: nombre,      // Asegúrate de tener estas variables en tu State
              telefono: telefono,
              contrasena: contrasena,
              avatarUrl: avatarUrl,
              onActualizar: _cargarDatos, // Pasamos la función para recargar datos
            ),
            
            const SizedBox(height: 20),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.red.shade100, width: 1.5),
              ),
              color: Colors.red.withOpacity(0.05), // Un fondo suave rojizo
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _isLoading ? null : _mostrarDialogoConfirmacion,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      // Círculo del icono
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
                      ),
                      const SizedBox(width: 15),
                      // Textos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Eliminar mi cuenta",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Esta acción no se puede deshacer",
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.red, size: 16),
                    ],
                  ),
                ),
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 15),
              const CircularProgressIndicator(color: Colors.red),
            ],

            const SizedBox(height: 20),

            const Text(
              "Gestiona tus datos y privacidad. Recuerda que eliminar tu cuenta es una acción permanente.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}