import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// --- ELEMENTOS DEL GRID (ACCIONES RÁPIDAS) ---
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
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => pagina),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: esOscuro ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: esOscuro ? Colors.white10 : Colors.grey.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Icon(
              icono,
              color: esOscuro ? Colors.white : const Color(0xFF2D2D2D),
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            titulo,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: esOscuro ? Colors.grey[400] : Colors.black87,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// --- TARJETA DE ACCIÓN CRÍTICA (ELIMINAR/ADVERTENCIA) ---
class LargeCardAction extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color colorPrincipal;
  final VoidCallback onTap;
  final bool isLoading;

  const LargeCardAction({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.onTap,
    this.colorPrincipal = Colors.redAccent,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorPrincipal.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorPrincipal.withOpacity(0.2), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorPrincipal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: colorPrincipal, size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(color: colorPrincipal, fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    subtitulo,
                    style: TextStyle(color: colorPrincipal.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colorPrincipal))
            else
              Icon(Icons.arrow_forward_ios_rounded, color: colorPrincipal, size: 14),
          ],
        ),
      ),
    );
  }
}

// --- BOTONES DE SESIÓN ---

class BotonLoginDiDi extends StatelessWidget {
  final Widget loginPage;
  const BotonLoginDiDi({super.key, required this.loginPage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 180, 195, 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => loginPage)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: const Text("Iniciar Sesión", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class BotonLogoutDiDi extends StatelessWidget {
  final VoidCallback onLogout;

  const BotonLogoutDiDi({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          // Lógica de logout optimizada
          try {
            final token = await FirebaseMessaging.instance.getToken().timeout(
                  const Duration(seconds: 1),
                  onTimeout: () => null,
                );
            if (token != null) {
              await Supabase.instance.client.from('fcm_tokens').delete().eq('token', token);
            }
          } catch (_) {}
          await Supabase.instance.client.auth.signOut();
          onLogout();
        },
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text("Cerrar Sesión", style: TextStyle(fontWeight: FontWeight.w800)),
        style: TextButton.styleFrom(
          foregroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
    );
  }
}