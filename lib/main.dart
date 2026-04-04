import 'package:flutter/material.dart';
import 'package:pbshop/pantallas/pantallas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'servicios/NotificacionesService.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 1. Definimos el canal de "Alta Importancia"
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'pbshop_canal_final', // ID único
    'Avisos de Pedidos PB-Shop', // Nombre que verá el usuario en ajustes
    description: 'Este canal se usa para avisos urgentes de los pedidos.',
    importance: Importance.max, // <--- CLAVE PARA EL POP-UP
    playSound: true,
    sound: RawResourceAndroidNotificationSound('noti'),
  );

  // 2. Registramos el canal en el sistema Android
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Inicialización de Supabase
  await Supabase.initialize(
    url: 'https://suqnkqncfrrougjmguck.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN1cW5rcW5jZnJyb3Vnam1ndWNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4NTcwMjQsImV4cCI6MjA4NjQzMzAyNH0.lF3qf2DwzhtsJ8FZ531bOpgUvG7pwQPHDUTN22nzOcw',
  );
  await NotificacionesService.inicializar();

  // Si el usuario ya está logueado, actualizamos su token
  if (Supabase.instance.client.auth.currentUser != null) {
    await NotificacionesService.configurarFirebase();
  }
  
  runApp(const PBShopApp());
}

class PBShopApp extends StatelessWidget {
  const PBShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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