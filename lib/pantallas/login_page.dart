import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class login_page extends StatefulWidget {
  const login_page({super.key});

  @override
  State<login_page> createState() => _LoginPageState();
}

class _LoginPageState extends State<login_page> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _extraerNombreDelCorreo(String email) {
    // 1. Quitamos el dominio @pascualbravo.edu.co
    String parteInicial = email.split('@')[0]; 
    
    // 2. Reemplazamos los puntos por espacios y ponemos la primera letra en mayúscula
    // Ejemplo: "juan.perez" -> "Juan Perez"
    List<String> palabras = parteInicial.split('.');
    return palabras.map((p) {
      if (p.isEmpty) return "";
      return p[0].toUpperCase() + p.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!email.endsWith('@pascualbravo.edu.co')) {
      _mostrarError("Usa tu correo institucional");
      return;
    }

    // EXTRAEMOS EL NOMBRE AUTOMÁTICAMENTE
    String nombreExtraido = _extraerNombreDelCorreo(email);

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'nombre': nombreExtraido, // Se guarda en raw_user_meta_data
          'rol': 'estudiante',
        },
      );
      _mostrarExito("¡Cuenta creada para $nombreExtraido!");
    } on AuthException catch (error) {
      _mostrarError(error.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: Colors.red));
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Acceso PB Shop")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.account_circle, size: 80, color: Color.fromRGBO(0, 180, 195, 1)),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo @pascualbravo.edu.co',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            
            if (_isLoading) const CircularProgressIndicator()
            else ...[
              ElevatedButton(
                onPressed: _signUp, // Botón de Crear Cuenta
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Crear Cuenta", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () { /* Aquí podrías llamar a signIn normal */ },
                child: const Text("¿Ya tienes cuenta? Inicia sesión"),
              ),
            ],

          ],
        ),
      ),
    );
  }
}