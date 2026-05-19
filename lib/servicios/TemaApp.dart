import 'package:flutter/material.dart';

class AppTema {
  // El único y verdadero notifier global para toda la app
  static final ValueNotifier<ThemeMode> notifier = ValueNotifier<ThemeMode>(ThemeMode.system);

  static void cambiarTema(ThemeMode modo) {
    notifier.value = modo;
  }
}