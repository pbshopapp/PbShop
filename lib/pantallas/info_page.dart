import 'package:flutter/material.dart';
import 'package:pbshop/pantallas/mis_pedidos_page.dart';
import 'package:pbshop/pantallas/configurar_neg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  // Color institucional turquesa
  final Color colorInstitucional = const Color.fromRGBO(0, 180, 195, 1);

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: esOscuro ? Colors.black : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Perfil",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: esOscuro ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER DE PERFIL (STREAM) ---
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('perfiles')
                  .stream(primaryKey: ['id'])
                  .eq('id', Supabase.instance.client.auth.currentUser?.id ?? ''),
              builder: (context, snapshot) {
                bool tieneDatos = snapshot.hasData && snapshot.data!.isNotEmpty;
                final perfil = tieneDatos ? snapshot.data!.first : null;
                
                final nombreStream = perfil?['nombre'] ?? 'Usuario del Pascual';
                final avatarStream = perfil?['avatar_url'] ?? 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y'; 
                final rolStream = perfil?['rol'] ?? 'Estudiante / Emprendedor';

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: esOscuro ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colorInstitucional, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundImage: NetworkImage(avatarStream),
                          onBackgroundImageError: (_, __) => const Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombreStream,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              rolStream,
                              style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // --- ACCIONES RÁPIDAS ---
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              children: [
                GridItemCuenta(icono: Icons.help_outline_rounded, titulo: "Ayuda", pagina: const help_page()),
                GridItemCuenta(icono: Icons.gavel_rounded, titulo: "Legales", pagina: const DocumentationPage()),
                GridItemCuenta(icono: Icons.shopping_bag_rounded, titulo: "Pedidos", pagina: const MisPedidosPage()),
                GridItemCuenta(icono: Icons.person_outline_rounded, titulo: "Cuenta", pagina: const MiCuentaPage()),
              ],
            ),

            const SizedBox(height: 35),

            // --- SECCIÓN DE GESTIÓN (SOLO PARA EMPRENDEDORES) ---
            const Text(
              "Tu Negocio",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 15),

            _buildActionCard(
              context,
              titulo: "Gestionar Productos",
              subtitulo: "Añade o edita lo que vendes",
              icono: Icons.inventory_2_outlined,
              pagina: const admin_neg_page(),
              esOscuro: esOscuro,
            ),
            
            const SizedBox(height: 12),

            _buildActionCard(
              context,
              titulo: "Configuración del Perfil",
              subtitulo: "Ubicación, logo y contacto",
              icono: Icons.storefront_rounded,
              pagina: const PanelCargaWrapper(),
              esOscuro: esOscuro,
            ),

            const SizedBox(height: 12),

            _buildActionCard(
              context,
              titulo: "Órdenes Recibidas",
              subtitulo: "Revisa quién te ha comprado",
              icono: Icons.auto_graph_rounded,
              pagina: const pedidos_neg_page(),
              esOscuro: esOscuro,
            ),

            const SizedBox(height: 40),

            // --- BOTÓN DE SESIÓN ---
            StreamBuilder<AuthState>(
              stream: Supabase.instance.client.auth.onAuthStateChange,
              builder: (context, snapshot) {
                final session = snapshot.data?.session;
                return (session != null) 
                  ? BotonLogoutDiDi(onLogout: () => Navigator.pushReplacementNamed(context, '/login')) 
                  : BotonLoginDiDi(loginPage: const login_page());
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para las tarjetas de gestión con mejor diseño
  Widget _buildActionCard(BuildContext context, {
    required String titulo, 
    required String subtitulo, 
    required IconData icono, 
    required Widget pagina,
    required bool esOscuro,
  }) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => pagina)),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: esOscuro ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: esOscuro ? Colors.white10 : Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorInstitucional.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: colorInstitucional, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(subtitulo, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// Wrapper para cargar el negocio (Igual al tuyo pero limpio)
class PanelCargaWrapper extends StatelessWidget {
  const PanelCargaWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return FutureBuilder(
      future: Supabase.instance.client
          .from('perfiles')
          .select('fk_negocio')
          .eq('id', userId ?? '')
          .single(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color.fromRGBO(0, 180, 195, 1))));
        }
        final idNegocio = snapshot.data?['fk_negocio'];
        if (idNegocio == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text("Tu cuenta no está vinculada a ningún negocio.")),
          );
        }
        return ConfigurarNegocioPage(idNegocio: idNegocio);
      },
    );
  }
}