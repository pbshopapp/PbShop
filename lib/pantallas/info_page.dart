import 'package:flutter/material.dart';
import 'package:pbshop/pantallas/documentation_page.dart';
import 'package:pbshop/pantallas/help_page.dart';
import 'package:pbshop/pantallas/login_page.dart';
import 'package:pbshop/pantallas/pedidos_neg_page.dart';
import 'package:pbshop/widgets/PanelPerfil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/pantallas/admin_neg_page.dart';
import 'package:pbshop/servicios/ObtenerDatosUser.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class info_page extends StatefulWidget {
  const info_page({super.key});

  @override
  State<info_page> createState() => _InfoPageState();
}

class _InfoPageState extends State<info_page> {
  String nombre = "Usuario no registrado";
  String telefono = "********";
  String contrasena = "********";
  String avatarUrl = "https://via.placeholder.com/150"; // valor por defecto

@override
void initState() {
  super.initState();
  _cargarDatos(); // Cargamos los datos por primera vez
}

// Creamos un método para (re)cargar los datos
Future<void> _cargarDatos() async {
  final obtenerDatosUser = ObtenerDatosUser();
  final perfil = await obtenerDatosUser.getDatosUsuario();
if (!mounted) return; // Verificamos que el widget sigue en pantalla antes de actualizar
  setState(() {
    nombre = perfil.name;
    telefono = perfil.phone;
    contrasena = perfil.password;
    avatarUrl = perfil.avatarUrl;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cuenta")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "PB Shop",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(0, 180, 195, 1),
            ),
          ),
          const SizedBox(height: 10),
          const Text("Proyecto de ecosistema digital para el Pascual Bravo."),
          const Divider(height: 40),

          // Perfil
          PerfilWidget(
            nombre: nombre,
            telefono: telefono,
            contrasena: contrasena,
            avatarUrl: avatarUrl,
          ),

          const SizedBox(height: 20),

          // Botón Ayuda
          _botonMenu(
            context,
            "Ayuda y contacto",
            Icons.help_outline,
            const help_page(),
          ),

          const SizedBox(height: 20),

          // Botón Términos
          _botonMenu(
            context,
            "Términos y condiciones",
            Icons.description,
            const documentation_page(),
          ),

          const SizedBox(height: 20),

          // Botón Panel Admin (solo para negocios)
          _botonMenu(
            context,
            "Panel de Negocio",
            Icons.admin_panel_settings_outlined,
            const admin_neg_page(),
          ),

          const SizedBox(height: 20),
          
          _botonMenu(
            context,
            "Ver Pedidos",
            Icons.shopping_cart_outlined,
            const pedidos_neg_page(),
          ),

          const SizedBox(height: 20),



          const SizedBox(height: 20),
          // --- SECCIÓN DINÁMICA DE LOGIN / LOGOUT ---
          StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              final session = snapshot.data?.session;
              final bool isLoggedIn = session != null;

              return isLoggedIn
                  ? _botonCerrarSesion(context)
                  : _botonIniciarSesion(context);
            },
          ),
        ],
      ),
    );
  }

  // Botón Iniciar Sesión
  Widget _botonIniciarSesion(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const login_page()),
          
        );
        setState(() {});
      },
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
      icon: const Icon(Icons.login),
      label: const Text("Iniciar Sesión"),
    );
  }

  // Botón Cerrar Sesión
  Widget _botonCerrarSesion(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            await Supabase.instance.client
                .from('fcm_tokens')
                .delete()
                .eq('token', token);
          }
          await Supabase.instance.client.auth.signOut();
        _cargarDatos(); // Limpiamos los datos al cerrar sesión
        setState(() {}); // Forzar actualización de UI después de cerrar sesión
      },
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        foregroundColor: Colors.redAccent,
        side: const BorderSide(color: Colors.redAccent),
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
      icon: const Icon(Icons.logout),
      label: const Text("Cerrar Sesión"),
    );
  }

  // Botón auxiliar
  Widget _botonMenu(
      BuildContext context, String titulo, IconData icono, Widget pagina) {
    return ElevatedButton.icon(
      onPressed: () =>
          Navigator.push(context, MaterialPageRoute(builder: (context) => pagina)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
      icon: Icon(icono),
      label: Text(titulo),
    );
  }
}