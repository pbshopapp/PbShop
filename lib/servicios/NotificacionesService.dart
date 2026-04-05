import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pbshop/pantallas/detalles_pedido_dinamico.dart';
import 'package:pbshop/main.dart'; // Asegúrate de que aquí esté definido el navigatorKey
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

    // 1. Manejar mensaje inicial (App cerrada totalmente)
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(seconds: 1), () {
        _manejarClic(initialMessage.data);
      });
    }

    // 2. Solicitar permisos (Indispensable para Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 3. Registro del Token en Supabase
      try {
        String? token = await messaging.getToken().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );

        if (token != null) {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            await Supabase.instance.client.from('fcm_tokens').upsert({
              'usuario_id': userId,
              'token': token,
            }, onConflict: 'token');
          }
        }
      } catch (e) {
        debugPrint("Error registrando token: $e");
      }

      // 4. ESCUCHA ACTIVA: App en primer plano (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // IMPORTANTE: Leemos de 'data' porque 'notification' viene nulo desde la Edge Function
        final String titulo = message.data['title'] ?? 'Nuevo aviso de PB-Shop';
        final String cuerpo = message.data['body'] ?? 'Revisa tu pedido ahora';
        
        mostrar(titulo, cuerpo, message.data);
      });

      // 5. ESCUCHA ACTIVA: App en segundo plano (Clic en la notificación)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _manejarClic(message.data);
      });
    }
  }

  static Future<void> inicializar() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Manejo de botones de acción
        if (details.payload != null) {
          final Map<String, dynamic> data = jsonDecode(details.payload!);
          if (details.actionId == 'id_ver_pedido') {
            _manejarClic(data);
          }
        }
      },
    );

    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> mostrar(String titulo, String cuerpo, Map<String, dynamic> data) async {
    final String? tipo = data['tipo_alerta'];
    
    // Vibración personalizada para urgencias
    final Int64List? patronVibracion = (tipo == "URGENTE") 
        ? Int64List.fromList([0, 1000, 500, 2000]) 
        : null;

    final detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        'pbshop_canal_final',
        'Avisos de Pedidos PB-Shop',
        importance: Importance.max,
        priority: Priority.max,
        sound: const RawResourceAndroidNotificationSound('campana'),
        vibrationPattern: patronVibracion,
        enableVibration: true,
        // Flag '4' hace que la notificación sea insistente (repite sonido hasta interactuar)
        additionalFlags: (tipo == "URGENTE") ? Int32List.fromList([4]) : null,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'id_silenciar', 
            'Silenciar', 
            cancelNotification: true,
            showsUserInterface: false,
          ),
          const AndroidNotificationAction(
            'id_ver_pedido', 
            'Ver Pedido', 
            cancelNotification: true,
            showsUserInterface: true,
          ),
        ],
      ),
    );

    await _plugin.show(
      DateTime.now().millisecond, 
      titulo, 
      cuerpo, 
      detalles, 
      payload: jsonEncode(data)
    );
  }
  
  static DateTime? _ultimoClic;
  static void _manejarClic(Map<String, dynamic> data) {
    final ahora = DateTime.now();
    if (_ultimoClic != null && ahora.difference(_ultimoClic!).inMilliseconds < 1000) return; 
    _ultimoClic = ahora;

    final String? screen = data['screen'];
    final String? idPedido = data['id_pedido'];

    if (navigatorKey.currentState == null) return;

    // Resetear al home y luego navegar al destino
    navigatorKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const home_page()),
      (route) => false,
    );

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