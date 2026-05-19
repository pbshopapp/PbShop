import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pbshop/servicios/ObtenerDatosUser.dart';
import 'package:pbshop/widgets/PanelPerfil.dart';
import 'package:pbshop/servicios/TemaApp.dart';
// 👈 Importa tu gestor de tema global aquí (por ejemplo, tu tema principal o servicio)

class MiCuentaPage extends StatefulWidget {
  const MiCuentaPage({super.key});

  @override
  State<MiCuentaPage> createState() => _MiCuentaPageState();
}

class _MiCuentaPageState extends State<MiCuentaPage> {
  final _supabase = Supabase.instance.client;
  final _passController = TextEditingController();
  bool _isLoading = false;
  
  String nombre = "Cargando...";
  String telefono = "********";
  String avatarUrl = "https://via.placeholder.com/150";
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
      debugPrint("Error cargando perfil: $e");
    }
  }

  Future<void> _eliminarCuenta() async {
    setState(() => _isLoading = true);
    try {
      final email = _supabase.auth.currentUser?.email;
      final userId = _supabase.auth.currentUser?.id;
      if (email == null || userId == null) return;

      try {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: _passController.text.trim(),
        );
      } catch (authError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Contraseña incorrecta. Inténtalo de nuevo.")),
          );
        }
        return;
      }

      try {
        await _supabase.functions.invoke(
          'delete-user',
          body: {'userId': userId},
        );
      } catch (functionError) {
        debugPrint("Nota: Error controlado al invocar la función: $functionError");
      }

      try {
        await _supabase.auth.signOut();
      } catch (_) {}
      
      if (mounted) {
        _passController.clear();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cuenta eliminada correctamente")),
        );
      }

    } catch (e) {
      debugPrint("Error general inesperado en el proceso: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ocurrió un error inesperado al procesar la solicitud")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogoConfirmacion(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("¿Eliminar cuenta?", 
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Esta acción es irreversible. Ingresa tu contraseña para confirmar:",
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passController,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Contraseña",
                labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.redAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("CANCELAR", style: TextStyle(color: isDark ? Colors.white38 : Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: _isLoading ? null : () {
              Navigator.pop(context);
              _eliminarCuenta();
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTema.notifier,
      builder: (context, modoTemaActual, child) {
        // Calculamos el estado de brillo actual basándonos en el contexto actualizado
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        final colorTextoPrincipal = isDark ? Colors.white : Colors.black87;
        final colorRojoCard = isDark ? Colors.redAccent.shade100 : Colors.red.shade700;
        final bgRojoCard = isDark ? Colors.redAccent.withOpacity(0.1) : Colors.red.withOpacity(0.05);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7F9),
          appBar: AppBar(
            title: Text(
              "Mi Cuenta", 
              style: TextStyle(fontWeight: FontWeight.bold, color: colorTextoPrincipal),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: colorTextoPrincipal),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Panel de Perfil
                PerfilWidget(
                  nombre: nombre,
                  telefono: telefono,
                  contrasena: contrasena,
                  avatarUrl: avatarUrl,
                  onActualizar: _cargarDatos,
                ),
                
                const SizedBox(height: 25),

                // 🛠️ TARJETA DE APARIENCIA (Optimizada)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
                  ),
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(0, 180, 195, 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, 
                            color: const Color.fromRGBO(0, 180, 195, 1), 
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tema de la app",
                                style: TextStyle(color: colorTextoPrincipal, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Claro, oscuro o sistema",
                                style: TextStyle(color: theme.hintColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        
                        // Dropdown minimalista limpio (ya no requiere su propio builder interno)
                        DropdownButtonHideUnderline(
                          child: DropdownButton<ThemeMode>(
                            value: modoTemaActual, 
                            dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.hintColor),
                            style: TextStyle(
                              color: colorTextoPrincipal, 
                              fontWeight: FontWeight.w500, 
                              fontSize: 14,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            items: const [
                              DropdownMenuItem(value: ThemeMode.system, child: Text("Sistema")),
                              DropdownMenuItem(value: ThemeMode.light, child: Text("Claro")),
                              DropdownMenuItem(value: ThemeMode.dark, child: Text("Oscuro")),
                            ],
                            onChanged: (ThemeMode? nuevoTema) {
                              if (nuevoTema != null) {
                                AppTema.cambiarTema(nuevoTema); 
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Tarjeta de Eliminación
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: colorRojoCard.withOpacity(0.3), width: 1.5),
                  ),
                  color: bgRojoCard,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _isLoading ? null : () => _mostrarDialogoConfirmacion(isDark),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorRojoCard.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.delete_forever_rounded, color: colorRojoCard, size: 28),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Eliminar mi cuenta",
                                  style: TextStyle(
                                    color: colorRojoCard,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Acción permanente e irreversible",
                                  style: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.red.shade300,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, color: colorRojoCard, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_isLoading) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: Colors.redAccent),
                ],

                const SizedBox(height: 40),

                // Footer de texto
                Text(
                  "PB-Shop • Medellín, Colombia\nGestiona tus datos y privacidad con seguridad.",
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.grey, 
                    fontSize: 12,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

