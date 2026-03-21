import 'package:supabase_flutter/supabase_flutter.dart';
import 'UserProfile.dart'; // importa el modelo

class ObtenerDatosUser {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> actualizarCampoPerfil(String columna, String nuevoValor) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client
          .from('perfiles')
          .update({columna: nuevoValor}) // Ej: {'nombre': 'Diego'}
          .eq('id', user.id);
      return true;
    } catch (e) {
      print("Error al actualizar $columna: $e");
      return false;
    }
  }

  /// Cambia la contraseña real de la cuenta en Supabase Auth
  Future<bool> cambiarContrasenaAuth(String nuevaPassword) async {
    try {
      // Esta es la instrucción que cambia la clave en el sistema de login
      await _client.auth.updateUser(
        UserAttributes(password: nuevaPassword),
      );
      return true;
    } catch (e) {
      print("Error de Auth: $e");
      return false;
    }
  }

  /// Obtiene los datos del usuario desde la tabla `profiles`
  Future<UserProfile> getDatosUsuario() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return UserProfile(
        name: "Usuario no registrado",
        phone: "********",
        password: "********",
        avatarUrl: "https://via.placeholder.com/150",
      );
    }

    try {
      final response = await _client
          .from('perfiles')
          .select('nombre, telefono, avatar_url')
          .eq('id', user.id)
          .single();

      return UserProfile.fromMap(response);
    } catch (e) {
      return UserProfile(
        name: "Error al obtener datos",
        phone: "********",
        password: "********",
        avatarUrl: "https://via.placeholder.com/150",
      );
    }
  }
}