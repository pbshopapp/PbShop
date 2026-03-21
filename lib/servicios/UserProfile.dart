class UserProfile {
  final String name;
  final String phone;
  final String password;
  final String avatarUrl;

  UserProfile({
    required this.name,
    required this.phone,
    required this.password,
    required this.avatarUrl,
  });

  // Constructor desde un Map (respuesta de Supabase)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['nombre'] ?? "Usuario sin nombre",
      phone: map['telefono'] ?? "Teléfono no registrado",
      password: map['password'] ?? "********",
      avatarUrl: map['avatar_url'] ?? "https://via.placeholder.com/150",
    );
  }
}