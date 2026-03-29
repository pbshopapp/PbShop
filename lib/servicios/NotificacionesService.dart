import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pbshop/pantallas/detalles_pedido_dinamico.dart';
import 'package:pbshop/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificacionesService {
  static final _plugin = FlutterLocalNotificationsPlugin();

 static Future<void> configurarFirebase() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

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
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null && token != null) {
      await Supabase.instance.client
          .from('perfiles') 
          .update({'fcm_token': token})
          .eq('id', userId);
    }

    // --- NUEVO: Escuchar mensajes cuando la app está abierta ---
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // Extraemos el id del pedido que viene en la "data" del mensaje
        String idPedido = message.data['id_pedido'] ?? '';
        
        // Llamamos a tu función mostrar para que salga el globito
        mostrar(
          message.notification!.title ?? 'Nuevo Aviso',
          message.notification!.body ?? '',
          idPedido,
          payload: idPedido, // Importante para que al tocarla navegue
        );
      }
    });

    // --- NUEVO: Manejar clic cuando la app estaba en segundo plano ---
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      String? idPedido = message.data['id_pedido'];
      if (idPedido != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => DetallePedidoDinamico(idPedido: idPedido),
          ),
        );
      }
    });
  }
}
  static Future<void> inicializar() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
       String? idDelPedido = response.payload;
        if (idDelPedido != null && navigatorKey.currentState != null) {
        // Navegamos a la pantalla de detalles pasando el ID
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => DetallePedidoDinamico(idPedido: idDelPedido),
            ),
          );
        }
      },
    );
    
    // Solicitar permisos para Android 13+
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> mostrar(String titulo, String cuerpo, String idPedido, {String? payload}) async {
    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        'pb_shop_canal', 'Pedidos PB-Shop',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    
    await _plugin.show(
      DateTime.now().millisecond, 
      titulo, 
      cuerpo, 
      detalles, 
      payload: payload ?? idPedido // Si no mandas payload, usa el idPedido
    );
  }
}