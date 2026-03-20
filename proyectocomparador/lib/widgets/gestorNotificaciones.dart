// ignore: file_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GestorNotificaciones {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> comprobarYMostrarNotificacion({
    required bool tieneNotificaciones,
    required String idUsuario,
    required int cantidadJuegos,
  }) async {
    if (!tieneNotificaciones || cantidadJuegos <= 0) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("activarNotificacion")
          .where("idUsuario", isEqualTo: idUsuario)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return;

      final data = snapshot.docs.first.data();

      final estado = data["estado"] ?? false;

      if (estado == false) return;
    } catch (e) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final claveTiempo = "ultima_notificacion_$idUsuario";
    const claveSesion = "usuario_actual";

    final usuarioGuardado = prefs.getString(claveSesion);
    final ahora = DateTime.now().millisecondsSinceEpoch;

    const int horas24 = 24 * 60 * 60 * 1000;

    if (usuarioGuardado != idUsuario) {
      await _mostrarNotificacion(cantidadJuegos);

      await prefs.setString(claveSesion, idUsuario);
      await prefs.setInt(claveTiempo, ahora);

      return;
    }

    final ultima = prefs.getInt(claveTiempo) ?? 0;

    if (ahora - ultima >= horas24) {
      await _mostrarNotificacion(cantidadJuegos);
      await prefs.setInt(claveTiempo, ahora);
    }
  }

  static Future<void> _mostrarNotificacion(int cantidadJuegos) async {
    const androidDetails = AndroidNotificationDetails(
      'canal_ofertas',
      'Ofertas juegos',
      channelDescription: 'Notificaciones de ofertas de juegos',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      '¡Tus juegos están en oferta!',
      'Hay $cantidadJuegos juegos que cumplen tus condiciones',
      details,
    );
  }
}
