import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Widget para los botones pequeños del Grid
class GridItemCuenta extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Widget pagina;

  const GridItemCuenta({
    super.key,
    required this.icono,
    required this.titulo,
    required this.pagina,
  });

 @override
  Widget build(BuildContext context) {
    return InkWell( // Cambié GestureDetector por InkWell para tener feedback visual al tocar
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => pagina),
      ),
      borderRadius: BorderRadius.circular(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity, 
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10), 
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                const BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04), 
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Icon(
              icono, 
              color: const Color.fromARGB(255, 27, 27, 27), 
              size: 30, 
            ),
          ),
          const SizedBox(height: 10),
          Text(
            titulo,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5, 
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para las tarjetas largas (Panel de Negocio)
class LargeCardCuenta extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color colorIcono;
  final Widget pagina;

  const LargeCardCuenta({
    super.key,
    required this.titulo,
    required this.icono,
    required this.colorIcono,
    required this.pagina,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icono, color: colorIcono),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => pagina),
        ),
      ),
    );
  }
}

// Botón Iniciar Sesión estilo DiDi
class BotonLoginDiDi extends StatelessWidget {
  final Widget loginPage;
  const BotonLoginDiDi({super.key, required this.loginPage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => loginPage),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: const Text("Iniciar Sesión",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// Botón Cerrar Sesión estilo DiDi
class BotonLogoutDiDi extends StatelessWidget {
  final VoidCallback onLogout; // Función para recargar datos después de salir

  const BotonLogoutDiDi({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          try {
            final token = await FirebaseMessaging.instance.getToken().timeout(
                  const Duration(seconds: 2),
                  onTimeout: () => null,
                );
            if (token != null) {
              await Supabase.instance.client
                  .from('fcm_tokens')
                  .delete()
                  .eq('token', token);
            }
          } catch (e) {
            debugPrint("Error al borrar token: $e");
          }
          await Supabase.instance.client.auth.signOut();
          onLogout(); // Llamamos a _cargarDatos() de la info_page
        },
        icon: const Icon(Icons.logout),
        label: const Text("Cerrar Sesión"),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}