import 'package:supabase_flutter/supabase_flutter.dart';


class AuthService {
  final supabase = Supabase.instance.client;

  Future<void> registrarUsuario(String email, String password, String nombreCompleto) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nombre': nombreCompleto, // Se envía al Trigger de la DB
        },
      );
      
      if (response.user != null) {
        print("Registro exitoso");
      }
    } catch (e) {
      print("Error al registrar: $e");
      rethrow; // Para que la pantalla pueda mostrar el error
    }
  }
}