// functions/index.js
// Cloud Function para enviar notificaciones push desde Firebase

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Enviar notificación cuando se crea un nuevo producto
exports.sendProductNotification = functions.firestore
  .document('products/{productId}')
  .onCreate(async (snap, context) => {
    const product = snap.data();
    
    // Obtener todos los tokens de usuarios
    const tokensSnapshot = await admin.firestore()
      .collection('user_tokens')
      .get();
    
    const tokens = tokensSnapshot.docs.map(doc => doc.data().token);
    
    if (tokens.length === 0) {
      console.log('No hay tokens disponibles');
      return null;
    }

    // Mensaje de notificación
    const message = {
      notification: {
        title: '🎉 Nuevo Producto',
        body: `Se agregó: ${product.name}`,
      },
      data: {
        type: 'product_created',
        productId: context.params.productId,
        productName: product.name,
      },
    };

    // Enviar notificación a todos los dispositivos
    try {
      const response = await admin.messaging().sendToDevice(tokens, message, {
        priority: 'high',
        timeToLive: 60 * 60 * 24, // 24 horas
      });
      
      console.log('Notificaciones enviadas:', response.successCount);
      
      // Guardar en historial
      await admin.firestore().collection('notifications_history').add({
        title: message.notification.title,
        body: message.notification.body,
        data: message.data,
        successCount: response.successCount,
        failureCount: response.failureCount,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return response;
    } catch (error) {
      console.error('Error al enviar notificación:', error);
      return null;
    }
  });

// Enviar notificación cuando el stock es bajo
exports.checkLowStock = functions.firestore
  .document('products/{productId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    // Verificar si el stock bajó a 10 o menos
    if (newData.stock <= 10 && oldData.stock > 10) {
      const tokensSnapshot = await admin.firestore()
        .collection('user_tokens')
        .get();
      
      const tokens = tokensSnapshot.docs.map(doc => doc.data().token);
      
      if (tokens.length === 0) return null;

      const message = {
        notification: {
          title: '⚠️ Stock Bajo',
          body: `${newData.name} tiene solo ${newData.stock} unidades`,
        },
        data: {
          type: 'low_stock',
          productId: context.params.productId,
          stock: String(newData.stock),
        },
      };

      try {
        const response = await admin.messaging().sendToDevice(tokens, message, {
          priority: 'high',
        });
        console.log('Alerta de stock bajo enviada:', response.successCount);
        return response;
      } catch (error) {
        console.error('Error al enviar alerta:', error);
        return null;
      }
    }
    
    return null;
  });

// Función HTTP para enviar notificación personalizada
exports.sendCustomNotification = functions.https.onCall(async (data, context) => {
  // Verificar autenticación (opcional)
  // if (!context.auth) {
  //   throw new functions.https.HttpsError('unauthenticated', 'Usuario no autenticado');
  // }

  const { title, body, tokens, topic } = data;

  if (!title || !body) {
    throw new functions.https.HttpsError('invalid-argument', 'Título y cuerpo requeridos');
  }

  const message = {
    notification: { title, body },
    data: data.data || {},
  };

  try {
    let response;
    
    if (topic) {
      // Enviar a un tópico
      response = await admin.messaging().sendToTopic(topic, message);
    } else if (tokens && tokens.length > 0) {
      // Enviar a tokens específicos
      response = await admin.messaging().sendToDevice(tokens, message);
    } else {
      throw new functions.https.HttpsError('invalid-argument', 'Tokens o tópico requeridos');
    }

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error('Error:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Limpiar tokens inválidos
exports.cleanupInvalidTokens = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const tokensSnapshot = await admin.firestore()
      .collection('user_tokens')
      .get();
    
    const batch = admin.firestore().batch();
    let deletedCount = 0;
    
    for (const doc of tokensSnapshot.docs) {
      const token = doc.data().token;
      
      try {
        // Intentar enviar un mensaje silencioso para validar el token
        await admin.messaging().send({
          token: token,
          data: { ping: 'test' },
        });
      } catch (error) {
        // Si falla, eliminar el token
        batch.delete(doc.ref);
        deletedCount++;
      }
    }
    
    await batch.commit();
    console.log(`Tokens inválidos eliminados: ${deletedCount}`);
    return null;
  });