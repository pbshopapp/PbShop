import 'package:flutter/material.dart';

class HorarioHelper {
  /// Recibe un string de horario (Ej: "8:00 AM - 7:00 PM") y retorna si está abierto
  static bool estaAbierto(String? horarioTexto) {
    if (horarioTexto == null) return true;

    try {
      String textoLimpio = horarioTexto.trim().toLowerCase();
      
      if (textoLimpio.isEmpty || textoLimpio == "24 horas" || !textoLimpio.contains('-')) {
        return true;
      }

      final partes = textoLimpio.split('-');
      if (partes.length != 2) return true;

      // Función interna auxiliar para mapear textos a minutos totales
      int convertirTextoAMinutos(String horaTexto) {
        horaTexto = horaTexto.trim();
        final regExp = RegExp(r'(\d+):(\d+)\s*(am|pm)');
        final match = regExp.firstMatch(horaTexto);

        if (match == null) {
          final regExpSinMinutos = RegExp(r'(\d+)\s*(am|pm)');
          final matchSinMinutos = regExpSinMinutos.firstMatch(horaTexto);
          if (matchSinMinutos != null) {
            int hora = int.parse(matchSinMinutos.group(1)!);
            String bloque = matchSinMinutos.group(2)!;
            if (bloque == 'pm' && hora != 12) hora += 12;
            if (bloque == 'am' && hora == 12) hora = 0;
            return hora * 60;
          }
          return 0;
        }

        int hora = int.parse(match.group(1)!);
        int minuto = int.parse(match.group(2)!);
        String bloque = match.group(3)!;

        if (bloque == 'pm' && hora != 12) hora += 12;
        if (bloque == 'am' && hora == 12) hora = 0;

        return (hora * 60) + minuto;
      }

      final int minutosApertura = convertirTextoAMinutos(partes[0]);
      final int minutosCierre = convertirTextoAMinutos(partes[1]);

      final ahora = DateTime.now();
      final int minutosActuales = (ahora.hour * 60) + ahora.minute;

      return minutosActuales >= minutosApertura && minutosActuales <= minutosCierre;
    } catch (e) {
      debugPrint("❌ ERROR EN HORARIO_HELPER: $e");
      return true; // Ante la duda o fallo, mejor dejar comprar al estudiante
    }
  }
}