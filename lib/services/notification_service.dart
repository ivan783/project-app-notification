// lib/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Guardar token de usuario en Firestore
  Future<void> saveUserToken(String userId, String token) async {
    try {
      await _firestore.collection('user_tokens').doc(userId).set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al guardar token: $e');
    }
  }

  // Obtener todos los tokens de usuarios
  Future<List<String>> getAllTokens() async {
    try {
      final snapshot = await _firestore.collection('user_tokens').get();
      return snapshot.docs.map((doc) => doc.data()['token'] as String).toList();
    } catch (e) {
      print('Error al obtener tokens: $e');
      return [];
    }
  }

  // Enviar notificación a un usuario específico
  Future<void> sendNotificationToUser({
    required String userToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _sendNotification(
      tokens: [userToken],
      title: title,
      body: body,
      data: data,
    );
  }

  // Enviar notificación a todos los usuarios
  Future<void> sendNotificationToAll({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final tokens = await getAllTokens();
    if (tokens.isEmpty) return;

    await _sendNotification(
      tokens: tokens,
      title: title,
      body: body,
      data: data,
    );
  }

  // Enviar notificación cuando se crea un producto
  Future<void> sendProductCreatedNotification(String productName) async {
    await sendNotificationToAll(
      title: '🎉 Nuevo Producto',
      body: 'Se agregó: $productName',
      data: {'type': 'product_created'},
    );
  }

  // Enviar notificación cuando el stock es bajo
  Future<void> sendLowStockNotification(String productName, int stock) async {
    await sendNotificationToAll(
      title: '⚠️ Stock Bajo',
      body: '$productName tiene solo $stock unidades',
      data: {'type': 'low_stock'},
    );
  }

  // Método privado para enviar notificaciones usando FCM HTTP v1 API
  Future<void> _sendNotification({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // IMPORTANTE: Este método usa Firebase Cloud Messaging API
    // Para usarlo en producción necesitas:
    // 1. Configurar Cloud Functions en Firebase
    // 2. O usar tu propio servidor backend
    
    // Ejemplo de estructura del mensaje
    for (String token in tokens) {
      final message = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'channel_id': 'high_importance_channel',
            }
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              }
            }
          }
        }
      };

      print('Mensaje preparado para enviar: ${json.encode(message)}');
      
      // NOTA: Para enviar notificaciones necesitas implementar
      // Cloud Functions o un backend con acceso a Firebase Admin SDK
      // Este es solo un ejemplo de la estructura del mensaje
    }
  }

  // Suscribir usuario a un tópico
  Future<void> subscribeToTopic(String token, String topic) async {
    try {
      // Implementar suscripción a tópico usando Firebase Cloud Messaging
      print('Usuario suscrito al tópico: $topic');
    } catch (e) {
      print('Error al suscribir a tópico: $e');
    }
  }

  // Guardar notificación en Firestore para historial
  Future<void> saveNotificationToHistory({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications_history').add({
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al guardar notificación: $e');
    }
  }
}