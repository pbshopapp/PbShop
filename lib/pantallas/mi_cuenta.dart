import 'package:flutter/material.dart';
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
            const Text(
              "Gestiona tus datos y privacidad. Recuerda que eliminar tu cuenta es una acción permanente.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const Spacer(), // Empuja el botón de eliminar hacia abajo
            const Divider(),

            ListTile(
              onTap: _mostrarDialogoConfirmacion,
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                "Eliminar mi cuenta", 
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
              ),
              subtitle: const Text("Borra todos tus datos de PB-Shop de forma definitiva"),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 10),
              const CircularProgressIndicator(),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}