import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pbshop/main.dart';
import 'package:pbshop/pantallas/admin_neg_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class login_page extends StatefulWidget {
  const login_page({super.key});

  @override
  State<login_page> createState() => _LoginPageState();
}
class _LoginPageState extends State<login_page> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telefonoController = TextEditingController();
  
  bool _isLoading = false;
  // CAMBIO 1: Ahora _isLogin empieza en 'true' para mostrar primero el inicio de sesión
  bool _isLogin = true; 

  String _extraerNombreDelCorreo(String email) {
    String parteInicial = email.split('@')[0]; 
    List<String> palabras = parteInicial.split('.');
    return palabras.map((p) {
      if (p.isEmpty) return "";
      return p[0].toUpperCase() + p.substring(1).toLowerCase();
    }).join(' ');
  }

  // FUNCIÓN PARA INICIAR SESIÓN
  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (response.user != null) {
        // Consultamos el rol para saber a dónde mandarlo
        final perfil = await Supabase.instance.client
            .from('perfiles')
            .select('rol')
            .eq('id', response.user!.id)
            .maybeSingle();

        if (mounted) {
          if (perfil != null && perfil['rol'] == 'admin_negocio') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const admin_neg_page()));
             // Cargamos los datos del nuevo usuario para mostrar su perfil actualizado en info_page
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const PBShopApp()), // Aquí pones el nombre de tu clase
              (route) => false, // Esto borra el historial para que no puedan volver al Login
            );
          }
        }
      }
    } on AuthException catch (error) {
      _mostrarError(error.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // TU FUNCIÓN DE REGISTRO (Se queda casi igual)
  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    if (!email.endsWith('@pascualbravo.edu.co')) {
      _mostrarError("Usa tu correo institucional");
      return;
    }
    // ... validación de teléfono ...
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: _passwordController.text.trim(),
        data: {
          'nombre': _extraerNombreDelCorreo(email),
          'telefono': _telefonoController.text.trim(),
          'rol': 'estudiante',
        },
      );
      _mostrarExito("¡Cuenta creada! Revisa tu correo.");
    } on AuthException catch (error) {
      _mostrarError(error.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: Colors.red));
  void _mostrarExito(String mensaje) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: Colors.green));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CAMBIO 2: Título dinámico según el estado
      appBar: AppBar(
        title: Text(_isLogin ? "Iniciar Sesión" : "Crear Cuenta PB Shop"),
        backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.account_circle, 
              size: 80, 
              color: Color.fromRGBO(0, 180, 195, 1)
            ),
            const SizedBox(height: 30),
            
            // CAMPO EMAIL
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo @pascualbravo.edu.co', 
                border: OutlineInputBorder(), 
                prefixIcon: Icon(Icons.email)
              ),
            ),
            const SizedBox(height: 15),
            
            // CAMPO PASSWORD
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña', 
                border: OutlineInputBorder(), 
                prefixIcon: Icon(Icons.lock)
              ),
            ),
            const SizedBox(height: 15),

            // CAMPO TELÉFONO (Solo se muestra en modo Registro)
            if (!_isLogin) ...[
              TextField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: "Teléfono Celular",
                  prefixText: "+57 ",
                  counterText: "",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 10),

            if (_isLoading) 
              const CircularProgressIndicator()
            else ...[
              // BOTÓN PRINCIPAL
              ElevatedButton(
                onPressed: () {
                  if (_isLogin) {
                    _signIn();
                  } else {
                    if (_telefonoController.text.length == 10) {
                      _signUp();
                    } else {
                      _mostrarError("El teléfono debe tener 10 dígitos");
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_isLogin ? "ENTRAR" : "REGISTRARME"),
              ),
              
              const SizedBox(height: 15),
              
              // BOTÓN PARA CAMBIAR DE MODO
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin 
                    ? "¿No tienes cuenta? Regístrate aquí" 
                    : "¿Ya tienes cuenta? Inicia sesión",
                  style: const TextStyle(color: Color.fromRGBO(0, 140, 155, 1)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}