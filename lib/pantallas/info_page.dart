import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbshop/pantallas/mis_pedidos_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Tus imports existentes
import 'package:pbshop/pantallas/documentation_page.dart';
import 'package:pbshop/pantallas/help_page.dart';
import 'package:pbshop/pantallas/login_page.dart';
import 'package:pbshop/pantallas/mi_cuenta.dart';
import 'package:pbshop/pantallas/pedidos_neg_page.dart';
import 'package:pbshop/pantallas/admin_neg_page.dart';
import 'package:pbshop/servicios/ObtenerDatosUser.dart';
import 'package:pbshop/widgets/widgetsInfo.dart';

class info_page extends StatefulWidget {
  const info_page({super.key});

  @override
  State<info_page> createState() => _InfoPageState();
}

class _InfoPageState extends State<info_page> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo gris claro estilo DiDi
      appBar: AppBar(
        title: const Text("Cuenta", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('perfiles')
                  .stream(primaryKey: ['id'])
                  .eq('id', Supabase.instance.client.auth.currentUser?.id ?? ''),
              builder: (context, snapshot) {
                // Si está cargando y no tiene datos previos, podrías mostrar un shimmer o dejar que pase
                // Pero para evitar que se quede "pensando" eternamente:
                
                bool tieneDatos = snapshot.hasData && snapshot.data!.isNotEmpty;
                
                // Extraemos los datos o usamos valores por defecto (Genéricos)
                final perfil = tieneDatos ? snapshot.data!.first : null;
                
                final nombreStream = perfil?['nombre'] ?? 'Sin nombre de usuario';
                final avatarStream = perfil?['avatar_url'] ?? 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y'; 
                final rolStream = perfil?['rol'] ?? 'Invitado';

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundImage: NetworkImage(avatarStream),
                          backgroundColor: Colors.grey[200],
                          // Si la imagen falla, ponemos un icono por defecto
                          onBackgroundImageError: (_, __) => const Icon(Icons.person),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombreStream,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                rolStream,
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        // Un indicador visual opcional de que está sincronizando (muy pequeño)
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 25),

            // --- REJILLA DE ACCIONES RÁPIDAS (Grid) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Para que no toque los bordes del celular
              child: GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12, 
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.72,
                ),
                children: [
                  GridItemCuenta(
                    icono: Icons.help_outline, 
                    titulo: "Ayuda", 
                    pagina: const help_page()
                  ),
                  GridItemCuenta(
                    icono: Icons.description_outlined, 
                    titulo: "Términos", 
                    pagina: const documentation_page()
                  ),
                  GridItemCuenta(
                    icono: Icons.shopping_bag_outlined, 
                    titulo: "Pedidos", 
                    pagina: const MisPedidosPage()
                  ),
                  GridItemCuenta(
                    icono: Icons.account_circle_outlined, 
                    titulo: "Mi Cuenta", 
                    pagina: const MiCuentaPage()
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- SECCIÓN DE GESTIÓN ---)
            const Text(
              "Gestión de Negocio",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Botón Panel de Negocio
            LargeCardCuenta(
              titulo: "Panel de Negocio",
              icono: Icons.admin_panel_settings_outlined,
              colorIcono: const Color.fromRGBO(0, 180, 195, 1),
              pagina: const admin_neg_page(),
            ),

            const SizedBox(height: 15),

            // Botón Pedidos del Negocio
            LargeCardCuenta(
              titulo: "Pedidos del Negocio",
              icono: Icons.receipt_long_outlined,
              colorIcono: const Color.fromRGBO(0, 180, 195, 1),
              pagina: const pedidos_neg_page(),
            ),

            const SizedBox(height: 30),

            // --- BOTÓN DE SESIÓN DINÁMICO ---
            StreamBuilder<AuthState>(
              stream: Supabase.instance.client.auth.onAuthStateChange,
              builder: (context, snapshot) {
                final session = snapshot.data?.session;
                return (session != null) 
                  ? BotonLogoutDiDi(onLogout: _cargarDatos)
                  : BotonLoginDiDi(loginPage: const login_page());
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }


}