import 'package:flutter/material.dart';
import 'package:pbshop/pantallas/documentation_page.dart';
import 'package:pbshop/pantallas/help_page.dart';
import 'package:pbshop/pantallas/login_page.dart'; // Asegúrate de importar tu nueva login_page
import 'package:supabase_flutter/supabase_flutter.dart';

class info_page extends StatelessWidget {
  const info_page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cuenta")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("PB Shop", 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromRGBO(0, 180, 195, 1))),
          const SizedBox(height: 10),
          const Text("Proyecto de ecosistema digital para el Pascual Bravo."),
          const Divider(height: 40),
          
          _itemFinanciero("Inversión", "Detalles del proyecto pascualino", Icons.trending_up, Colors.blue),
          
          const SizedBox(height: 20),
          
          // Botón Ayuda
          _botonMenu(
            context, 
            "Ayuda y contacto", 
            Icons.help_outline, 
            const help_page()
          ),
          
          const SizedBox(height: 20),
          
          // Botón Términos
          _botonMenu(
            context, 
            "Términos y condiciones", 
            Icons.description, 
            const documentation_page()
          ),

          const SizedBox(height: 40),

          // --- SECCIÓN DINÁMICA DE LOGIN / LOGOUT ---
          StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              // Verificamos si hay una sesión activa
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

  // Widget para el botón de Iniciar Sesión
  Widget _botonIniciarSesion(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const login_page()));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      icon: const Icon(Icons.login),
      label: const Text("Iniciar Sesión"),
    );
  }

  // Widget para el botón de Cerrar Sesión
  Widget _botonCerrarSesion(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        await Supabase.instance.client.auth.signOut();
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.redAccent,
        side: const BorderSide(color: Colors.redAccent),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      icon: const Icon(Icons.logout),
      label: const Text("Cerrar Sesión"),
    );
  }

  // Widget auxiliar para no repetir código de botones
  Widget _botonMenu(BuildContext context, String titulo, IconData icono, Widget pagina) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => pagina)),
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

  Widget _itemFinanciero(String titulo, String subtitulo, IconData icono, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icono, color: color)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitulo),
      ),
    );
  }
}