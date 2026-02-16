import 'package:flutter/material.dart';
import 'package:pbshop/pantallas/pantallas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Supabase
  await Supabase.initialize(
    url: 'https://suqnkqncfrrougjmguck.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN1cW5rcW5jZnJyb3Vnam1ndWNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4NTcwMjQsImV4cCI6MjA4NjQzMzAyNH0.lF3qf2DwzhtsJ8FZ531bOpgUvG7pwQPHDUTN22nzOcw',
  );

  runApp(const PBShopApp());
}

class PBShopApp extends StatelessWidget {
  const PBShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PB Shop',
      theme: ThemeData(
        primaryColor: const Color.fromRGBO(0, 180, 195, 1),
        useMaterial3: true,
      ),
      // Definimos la pantalla de inicio (login o home)
      home: const home_page(), 
    );
  }
}