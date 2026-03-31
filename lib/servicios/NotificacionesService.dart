import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pbshop/pantallas/detalles_pedido_dinamico.dart';
import 'package:pbshop/main.dart';
import 'package:pbshop/pantallas/home_page.dart';
import 'package:pbshop/pantallas/pedidos_neg_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';


class NotificacionesService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  
 static Future<void> configurarFirebase() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    print("App abierta desde CERRADO con data: ${initialMessage.data}");
    // Agregamos un pequeño delay para dar tiempo a que el Navigator esté listo
    Future.delayed(const Duration(seconds: 1), () {
      _manejarClic(initialMessage.data);
    });
  }

  // 2. ESCUCHAR CUANDO LA APP ESTÁ EN SEGUNDO PLANO
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("App abierta desde SEGUNDO PLANO con data: ${message.data}");
    _manejarClic(message.data);
  });
  // 1. Solicitar permisos
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      print("TOKEN DE FIREBASE: $token");

      // Guardar en Supabase
      // Guardar en Supabase (Nueva tabla fcm_tokens)
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId != null && token != null) {
        await Supabase.instance.client
            .from('fcm_tokens') // <--- CAMBIO: Nombre de la tabla nueva
            .upsert({           // <--- CAMBIO: Usamos upsert para evitar duplicados
              'usuario_id': userId,
              'token': token,
            }, onConflict: 'token'); // Si el token ya existe para este usuario, solo lo ignora o actualiza
            
        print("Token registrado exitosamente en fcm_tokens");
      }
          // --- NUEVO: Escuchar mensajes cuando la app está abierta ---
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            if (message.notification != null) {
              String idPedido = message.data['id_pedido'] ?? '';
              String screen = message.data['screen'] ?? 'ESTUDIANTE'; // <--- Recuperamos el screen

              mostrar(
                message.notification!.title ?? 'Nuevo Aviso',
                message.notification!.body ?? '',
                idPedido,
                screen, // <--- Se lo pasamos a la función mostrar
              );
            }
          });

          // --- NUEVO: Manejar clic cuando la app estaba en segundo plano ---
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
            print("Notificación tocada (App en segundo plano): ${message.data}");
            _manejarClic(message.data);
          });
    }
  }
  static Future<void> inicializar() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        String? payload = response.payload;
        if (payload != null && payload.contains('|')) {
          // Separamos el screen del idPedido
          final partes = payload.split('|');
          final String screen = partes[0];
          final String idPedido = partes[1];

          // Usamos la lógica centralizada que ya creaste
          _manejarClic({'screen': screen, 'id_pedido': idPedido});
        }
      },
    );
    
    // Solicitar permisos para Android 13+
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> mostrar(String titulo, String cuerpo, String idPedido, String screen) async { // <--- Agregamos screen
    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        'pb_shop_canal', 'Pedidos PB-Shop',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('noti'),
        playSound: true
      ),
    );
    
    // Guardamos ambos datos separados por un pipe |
    String payloadData = "$screen|$idPedido";

    await _plugin.show(
      DateTime.now().millisecond, 
      titulo, 
      cuerpo, 
      detalles, 
      payload: payloadData // <--- Enviamos la combinación
    );
  }
  
  static DateTime? _ultimoClic;
  static void _manejarClic(Map<String, dynamic> data) {
    final ahora = DateTime.now();
    if (_ultimoClic != null && ahora.difference(_ultimoClic!).inMilliseconds < 1000) {
      return; 
    }
    _ultimoClic = ahora;
    final String? screen = data['screen'];
    final String? idPedido = data['id_pedido'];

    if (navigatorKey.currentState == null) return;

    print("DEBUG: Screen recibida: $screen"); // <--- MIRA ESTO EN LA CONSOLA

    navigatorKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const home_page()), // Esta es la nueva "base"
      (route) => false, // Esto borra absolutamente todo el historial anterior
    );

    // 2. Encima del home, lanzamos la pantalla específica
    if (screen == "TENDERO") {
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (context) => const pedidos_neg_page()),
      );
    } else if (screen == "ESTUDIANTE" && idPedido != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => DetallePedidoDinamico(idPedido: idPedido),
        ),
      );
    }
  }
}