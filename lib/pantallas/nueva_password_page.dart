import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NuevaPasswordPage extends StatefulWidget {
  const NuevaPasswordPage({super.key});

  @override
  State<NuevaPasswordPage> createState() => _NuevaPasswordPageState();
}

class _NuevaPasswordPageState extends State<NuevaPasswordPage> {
  final _nuevaPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _actualizarPassword() async {
    if (_nuevaPassController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La contraseña debe tener al menos 6 caracteres")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _nuevaPassController.text.trim()),
      );
      
      if (mounted) {
        // Llamamos directamente al Widget de la pantalla
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NuevaPasswordPage()),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Contraseña"), backgroundColor: const Color.fromRGBO(0, 180, 195, 1), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Ingresa tu nueva contraseña para PB-Shop", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 25),
            TextField(
              controller: _nuevaPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Nueva contraseña", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_reset)),
            ),
            const SizedBox(height: 20),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _actualizarPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("ACTUALIZAR CONTRASEÑA"),
                ),
          ],
        ),
      ),
    );
  }
}