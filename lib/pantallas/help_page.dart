
import 'package:flutter/material.dart';
//import 'package:url_launcher/url_launcher.dart'; // Para abrir WhatsApp o Correo

class help_page extends StatelessWidget {
  const help_page({super.key});

  // Función para contactar a soporte (WhatsApp simulado)
  void _contactarSoporte(String plataforma) async {
    print("Contactando vía $plataforma...");
    // Aquí podrías usar url_launcher para abrir links reales
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Centro de Ayuda"),
        backgroundColor: const Color.fromRGBO(0, 180, 195, 1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Encabezado con Icono
            Container(
              width: double.infinity,
              color: const Color.fromRGBO(0, 180, 195, 0.05),
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Icon(Icons.help_outline, size: 80, color: Color.fromRGBO(0, 180, 195, 1)),
                  const SizedBox(height: 10),
                  const Text(
                    "¿Cómo podemos ayudarte?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text("PB Shop - Comunidad Pascualina", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),

            // Sección de Preguntas Frecuentes (FAQ)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Preguntas Frecuentes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildFAQItem(
                    "¿Cómo realizo un pedido?",
                    "Busca tu producto o tienda favorita, agrégalo al carrito y dale a 'Finalizar Pedido'. El vendedor recibirá tu orden al instante.",
                  ),
                  _buildFAQItem(
                    "¿Cuáles son los métodos de pago?",
                    "Cada tienda maneja sus métodos. La mayoría acepta efectivo, Nequi o transferencia directa al momento de la entrega.",
                  ),
                  _buildFAQItem(
                    "¿Qué hago si mi pedido no llega?",
                    "Puedes contactar directamente al negocio a través del chat de la app o dirigirte al bloque indicado en la ubicación del producto.",
                  ),
                  _buildFAQItem(
                    "¿Cómo registro mi propio negocio?",
                    "Dirígete a tu perfil y selecciona 'Convertirse en Vendedor' para empezar a vender tus productos en el campus.",
                  ),
                ],
              ),
            ),

            const Divider(),

            // Sección de Contacto Directo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("¿Aún tienes dudas?", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  ListTile(
                    leading: const Icon(Icons.email_outlined, color: Colors.redAccent),
                    title: const Text("Correo Electrónico"),
                    subtitle: const Text("pbshopapp@gmail.com"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _contactarSoporte("Email"),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            const Text("Versión 1.0.0 (Beta)", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget para cada pregunta desplegable
  Widget _buildFAQItem(String pregunta, String respuesta) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(pregunta, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(respuesta, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          ),
        ],
      ),
    );
  }
}