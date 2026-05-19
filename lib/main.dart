import 'package:flutter/material.dart';
import 'package:pbshop/pantallas/pantallas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'servicios/NotificacionesService.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'servicios/TemaApp.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Extraer datos del mapa 'data' (del index.ts de Supabase)
  final String titulo = message.data['title'] ?? 'Aviso de PB-Shop';
  final String cuerpo = message.data['body'] ?? 'Tienes una actualización';

  // Usamos el método estático de tu servicio que ya tiene los botones y la campana
  await NotificacionesService.mostrar(titulo, cuerpo, message.data);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 1. Definimos el canal de "Alta Importancia"
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'pbshop_canal_final', // ID único
    'Avisos de Pedidos PB-Shop', // Nombre que verá el usuario en ajustes
    description: 'Este canal se usa para avisos urgentes de los pedidos.',
    importance: Importance.max, // <--- CLAVE PARA EL POP-UP
    playSound: true,
    sound: RawResourceAndroidNotificationSound('campana'),
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTema.notifier, // 👈 2. Escucha al archivo centralizado
      builder: (context, modoTemaActual, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'PB Shop',
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color.fromRGBO(0, 180, 195, 1),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(backgroundColor: Color.fromRGBO(0, 180, 195, 1)),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color.fromRGBO(0, 180, 195, 1),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212), 
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1F1F1F)),
            cardTheme: const CardThemeData(color: Color(0xFF1E1E1E)),
          ),
          themeMode: modoTemaActual, // 👈 3. Aplica el cambio
          home: const home_page(), 
        );
      },
    );
  }
}