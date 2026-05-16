import 'package:flutter/material.dart';

class DocumentationPage extends StatelessWidget {
  const DocumentationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Detectamos las propiedades del tema actual del dispositivo
    final theme = Theme.of(context);
    const primaryColor = Color.fromRGBO(0, 180, 195, 1);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Términos y Condiciones"),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        foregroundColor: theme.appBarTheme.foregroundColor ?? const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("PB-SHOP: Términos y Condiciones de Uso", primaryColor),
            const SizedBox(height: 10),
            Center(
              child: Text(
                "Última actualización: 15 de Mayo, 2026",
                style: TextStyle(fontSize: 12, color: theme.hintColor, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20),
            
            _bodyText("PB-Shop es una aplicación informativa cuyo objetivo es centralizar y mostrar los productos, precios e información de negocios internos y cercanos a la Institución Universitaria Pascual Bravo.", context),
            Divider(height: 40, color: theme.dividerColor),

            _sectionTitle("1. Naturaleza del servicio", context),
            _bodyText("PB-Shop NO es una plataforma de pagos ni un intermediario comercial. Funciona estrictamente como un medio informativo y de contacto de libre acceso. No procesa transacciones, no realiza entregas y no garantiza la disponibilidad ni veracidad de los productos ofertados por terceros.", context),

            _sectionTitle("2. Responsabilidad sobre pedidos", context),
            _bodyText("Los pedidos e intenciones de compra se envían directamente a los canales de contacto provistos por los negocios de forma independiente. PB-Shop no tiene control sobre estas interacciones y no se hace responsable por:", context),
            _bulletPoint("Retrasos, modificaciones en la entrega o cancelaciones por parte del comercio.", primaryColor, context),
            _bulletPoint("Errores en los precios publicados, variaciones o productos agotados.", primaryColor, context),
            _bulletPoint("Calidad, idoneidad, estado del producto o cualquier acuerdo o disputa entre el usuario y el negocio.", primaryColor, context),

            _sectionTitle("3. Pagos y transacciones financieras", context),
            _bodyText("No gestionamos, recaudamos ni procesamos pagos de ninguna índole. Los métodos de pago son definidos y operados autónomamente por cada negocio. El envío de capturas de pantalla de transferencias a través de la app se realiza bajo exclusiva responsabilidad del usuario como medio de referencia de su comunicación, y no constituye una validación de pago por parte de la plataforma.", context),

            _sectionTitle("4. Reseñas, comentarios y contenido del usuario", context),
            _bodyText("Las opiniones reflejadas en la aplicación pertenecen exclusivamente a los usuarios que las emiten. PB-Shop no comparte ni se co-responsabiliza de dichas afirmaciones y se reserva el derecho absoluto de moderar, ocultar o eliminar cualquier contenido que se considere ofensivo, difamatorio, falso o que vulnere la convivencia de la comunidad universitaria.", context),

            _sectionTitle("5. Propiedad intelectual y protección de la idea", context),
            _bodyText("El software PB-Shop, incluyendo su código fuente, arquitectura, algoritmos, interfaces gráficas, logotipos, bases de datos y marca, son propiedad exclusiva de sus desarrolladores independientes. Está protegido por la Ley 23 de 1982, la Decisión Andina 351 de 1993 y demás normas de propiedad intelectual en Colombia. Queda estrictamente prohibida la reproducción total o parcial, explotación comercial no autorizada, descompilación o ingeniería inversa de la aplicación.", context),

            _sectionTitle("6. Protección de datos personales (Habeas Data)", context),
            _bodyText("En cumplimiento de la Ley 1581 de 2012 de Colombia, PB-Shop informa que los datos básicos recolectados (como nombres o números de contacto para redirección de pedidos) se tratan con la única finalidad de permitir el funcionamiento del servicio técnico de la app. No se compartirán ni venderán bases de datos a terceros con fines publicitarios ajenos a la plataforma. El usuario puede solicitar la supresión de sus datos en cualquier momento desinstalando la app o contactando al soporte.", context),

            _sectionTitle("7. Enlaces y redirecciones a terceros", context),
            _bodyText("La aplicación puede contener enlaces o botones que redirigen a servicios externos (como chats de WhatsApp, redes sociales o llamadas telefónicas). PB-Shop no controla, aprueba ni asume responsabilidad alguna por las políticas de privacidad, seguridad o contenidos de dichos sitios externos.", context),

            _sectionTitle("8. Relación con la Universidad", context),
            _bodyText("PB-Shop es un proyecto de desarrollo tecnológico totalmente independiente y autónomo. No representa oficialmente a la Institución Universitaria Pascual Bravo, ni compromete sus directrices, administración o responsabilidad legal.", context),

            const SizedBox(height: 30),
            _buildFooter(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE ESTILO (Adaptables al Tema) ---

  Widget _buildHeader(String text, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        // Usamos la opacidad del color primario para que funcione tanto en luz como en oscuridad
        color: primaryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.bold, 
          color: primaryColor
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _sectionTitle(String title, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title, 
        style: TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold, 
          // Utiliza el color de texto principal del tema activo
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _bodyText(String text, BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text, 
      style: TextStyle(
        fontSize: 14, 
        // Utiliza un color secundario/suave según el tema para el texto de cuerpo
        color: theme.colorScheme.onSurface.withOpacity(0.7), 
        height: 1.4,
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _bulletPoint(String text, Color primaryColor, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 10, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
          Expanded(child: _bodyText(text, context)),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        // Se adapta al color de tarjeta/contenedor secundario del tema actual
        color: theme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Text(
        "Al descargar, registrarse o utilizar de cualquier forma la aplicación PB-Shop, el usuario manifiesta que conoce y acepta estos Términos y Condiciones en su totalidad. Si no está de acuerdo, deberá abstenerse de usar la plataforma. Nos reservamos el derecho de modificar este documento en cualquier momento.",
        style: TextStyle(fontSize: 12, color: theme.hintColor, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }
}