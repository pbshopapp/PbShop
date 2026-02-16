import 'package:flutter/material.dart';

class documentation_page extends StatelessWidget {
  const documentation_page({super.key});

@override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromRGBO(0, 180, 195, 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Términos y Condiciones"),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("PB-SHOP: Términos y Condiciones de Uso"),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "Última actualización: 12 de Febrero, 2026",
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20),
            
            _bodyText("PB-Shop es una aplicación informativa cuyo objetivo es centralizar y mostrar los productos, precios e información de negocios internos y cercanos a la Universidad Pascual Bravo."),
            const Divider(height: 40),

            _sectionTitle("1. Naturaleza del servicio"),
            _bodyText("PB-Shop NO es una plataforma de pagos ni un intermediario comercial. Funciona como un medio informativo y de contacto. No procesa pagos, no realiza entregas y no garantiza la disponibilidad."),

            _sectionTitle("2. Responsabilidad sobre pedidos"),
            _bodyText("Los pedidos se envían directamente a los negocios. PB-Shop no se hace responsable por:"),
            _bulletPoint("Retrasos en la entrega o cancelaciones."),
            _bulletPoint("Errores en precios o productos agotados."),
            _bulletPoint("Calidad del producto o acuerdos entre usuario y negocio."),

            _sectionTitle("3. Pagos"),
            _bodyText("No gestionamos pagos. Los métodos son definidos por cada negocio. Las capturas de pago enviadas son solo referencia y no son validadas por la plataforma."),

            _sectionTitle("4. Reseñas y comentarios"),
            _bodyText("Reflejan opiniones personales. PB-Shop se reserva el derecho de moderar, ocultar o eliminar contenido ofensivo o falso."),

            _sectionTitle("5. Relación con la Universidad"),
            _bodyText("PB-Shop es un proyecto independiente y no representa oficialmente a la Institución Universitaria Pascual Bravo, salvo que se indique lo contrario."),

            const SizedBox(height: 30),
            _buildFooter(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE ESTILO (Reutilizables y sin errores) ---

  Widget _buildHeader(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 180, 195, 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.bold, 
          color: Color.fromRGBO(0, 180, 195, 1)
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title, 
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)
      ),
    );
  }

  Widget _bodyText(String text) {
    return Text(
      text, 
      style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4)
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromRGBO(0, 180, 195, 1))),
          Expanded(child: _bodyText(text)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        "Al usar esta aplicación, el usuario acepta estos términos en su totalidad. PB-Shop se reserva el derecho de modificar estos términos en cualquier momento.",
        style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }
}