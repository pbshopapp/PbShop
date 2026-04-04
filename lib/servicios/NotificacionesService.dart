import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pbshop/pantallas/detalles_pedido_dinamico.dart';
import 'package:pbshop/main.dart';
import 'package:pbshop/pantallas/home_page.dart';
import 'package:pbshop/pantallas/pedidos_neg_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'dart:typed_data';

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
      // 1. REGISTRO DEL TOKEN (Lógica de red)
      try {
        String? token = await messaging.getToken().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );

        if (token != null) {
          print("TOKEN DE FIREBASE: $token");
          final userId = Supabase.instance.client.auth.currentUser?.id;

          if (userId != null) {
            await Supabase.instance.client.from('fcm_tokens').upsert({
              'usuario_id': userId,
              'token': token,
            }, onConflict: 'token');
            print("Token registrado exitosamente en fcm_tokens");
          }
        }
      } catch (e) {
        print("Error al procesar el token: $e");
      }

      // 2. CONFIGURACIÓN DE ESCUCHA (Fuera del bloque del token)
      // Esto debe ejecutarse SIEMPRE que haya permisos, funcione el token o no.
      
      // App abierta
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          mostrar(
            message.notification!.title ?? '',
            message.notification!.body ?? '',
            message.data, 
          );
        }
      });

      // App en segundo plano (clic)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("Notificación tocada: ${message.data}");
        _manejarClic(message.data);
      });
    }
  }
  static Future<void> inicializar() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.actionId == 'id_ver_pedido' && details.payload != null) {
          // Ahora sí decodificamos tranquilos
          final Map<String, dynamic> data = jsonDecode(details.payload!);
          _manejarClic(data);
        }
      },
    );
    
    // Solicitar permisos para Android 13+
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> mostrar(String titulo, String cuerpo, Map<String, dynamic> data) async {
    final String? tipo = data['tipo_alerta'];
    
    // Configuramos la vibración solo si es URGENTE
    final Int64List? patronVibracion = (tipo == "URGENTE") 
        ? Int64List.fromList([0, 1000, 500, 2000]) 
        : null;

    final detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        'pbshop_canal_final',
        'Avisos de Pedidos PB-Shop',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        sound: RawResourceAndroidNotificationSound('campana'),
        vibrationPattern: patronVibracion,
        enableVibration: true,

        additionalFlags: (tipo == "URGENTE") 
            ? Int32List.fromList([4]) // El valor 4 es el código interno para 'Insistent' en Android
            : null, // Solo repite si es listo

        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'id_silenciar', 
            'Solo Silenciar', 
            cancelNotification: true, // Esto mata la vibración de una
            showsUserInterface: false, // NO abre la app
          ),
          AndroidNotificationAction(
            'id_ver_pedido', 
            'Ver Pedido', 
            cancelNotification: true,
            showsUserInterface: true, // SI abre la app
          ),
        ],
      ),
    );

    print("DEBUG: Intentando mostrar botones para tipo: $tipo");
    if (tipo == "URGENTE") {
      print("DEBUG: Configurando botones 'Silenciar' y 'Ver Pedido'");
    }
    await _plugin.show(
      DateTime.now().millisecond, 
      titulo, 
      cuerpo, 
      detalles, 
      payload: jsonEncode(data) // Pasamos toda la data
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