// ============================================================
// Integracion con Firebase Cloud Messaging (FCM) v1
// y Firestore REST API para persistencia
// ============================================================

import type { Env } from './types';

// Cache del access token de Firebase
let firebaseAccessToken: string | null = null;
let firebaseTokenExpiresAt = 0;

// ============================================================
// Autenticacion con Firebase usando Service Account JWT
// ============================================================

// Genera un JWT firmado con RS256 usando Web Crypto API
async function generateJWT(serviceAccountKey: string): Promise<string> {
  const sa = JSON.parse(serviceAccountKey) as {
    client_email: string;
    private_key: string;
    token_uri: string;
  };

  const now = Math.floor(Date.now() / 1000);

  // Header JWT
  const header = { alg: 'RS256', typ: 'JWT' };

  // Payload JWT
  const payload = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging https://www.googleapis.com/auth/datastore',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now
  };

  // Codificar header y payload
  const encoder = new TextEncoder();
  const headerB64 = base64urlEncode(JSON.stringify(header));
  const payloadB64 = base64urlEncode(JSON.stringify(payload));
  const unsignedToken = `${headerB64}.${payloadB64}`;

  // Importar la clave privada RSA
  const pemContent = sa.private_key
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\n/g, '');

  const binaryDer = Uint8Array.from(atob(pemContent), c => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryDer.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );

  // Firmar el token
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    encoder.encode(unsignedToken)
  );

  const signatureB64 = base64urlEncode(
    String.fromCharCode(...new Uint8Array(signature))
  );

  return `${unsignedToken}.${signatureB64}`;
}

// Obtiene un access token de Firebase usando el JWT del service account
async function getFirebaseAccessToken(env: Env): Promise<string> {
  // Usar token cacheado si aun es valido
  if (firebaseAccessToken && Date.now() < firebaseTokenExpiresAt - 300000) {
    return firebaseAccessToken;
  }

  const jwt = await generateJWT(env.FIREBASE_SERVICE_ACCOUNT_KEY);

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt
    })
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Error al obtener token de Firebase: ${error}`);
  }

  const data = await response.json() as { access_token: string; expires_in: number };
  firebaseAccessToken = data.access_token;
  firebaseTokenExpiresAt = Date.now() + data.expires_in * 1000;

  return firebaseAccessToken;
}

// ============================================================
// Firebase Cloud Messaging
// ============================================================

// Obtiene el token del dispositivo desde Firestore
async function getDeviceToken(env: Env): Promise<string | null> {
  const token = await getFirebaseAccessToken(env);
  const projectId = env.FIREBASE_PROJECT_ID;

  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/devices/adrian-iphone`,
    {
      headers: { Authorization: `Bearer ${token}` }
    }
  );

  if (!response.ok) {
    console.error('Error al obtener token del dispositivo:', response.status);
    return null;
  }

  const data = await response.json() as {
    fields?: {
      token?: { stringValue: string };
    };
  };

  return data.fields?.token?.stringValue || null;
}

// Envia una notificacion push via FCM v1
export async function sendPushNotification(
  title: string,
  body: string,
  priority: string,
  env: Env
): Promise<string> {
  const accessToken = await getFirebaseAccessToken(env);
  const deviceToken = await getDeviceToken(env);

  if (!deviceToken) {
    return 'No se encontró el token del dispositivo. Asegúrate de que la app esté registrada.';
  }

  const projectId = env.FIREBASE_PROJECT_ID;

  const message = {
    message: {
      token: deviceToken,
      notification: { title, body },
      android: {
        priority: priority === 'high' ? 'HIGH' : 'NORMAL'
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: 'default',
            badge: 1
          }
        },
        headers: {
          'apns-priority': priority === 'high' ? '10' : '5'
        }
      },
      data: {
        type: 'notification',
        title,
        body
      }
    }
  };

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(message)
    }
  );

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Error al enviar notificación: ${error}`);
  }

  // Guardar registro de la notificacion
  await saveNotification('push', title, body, env);

  return `Notificación enviada: "${title}"`;
}

// ============================================================
// Firestore REST API
// ============================================================

// Guarda una notificacion en Firestore
export async function saveNotification(
  type: string,
  title: string,
  body: string,
  env: Env
): Promise<void> {
  const accessToken = await getFirebaseAccessToken(env);
  const projectId = env.FIREBASE_PROJECT_ID;

  const document = {
    fields: {
      type: { stringValue: type },
      title: { stringValue: title },
      body: { stringValue: body },
      timestamp: { timestampValue: new Date().toISOString() },
      read: { booleanValue: false }
    }
  };

  await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/notifications`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(document)
    }
  );
}

// Lista notificaciones recientes desde Firestore
export async function listNotifications(env: Env): Promise<Array<{
  type: string;
  title: string;
  body: string;
  timestamp: string;
}>> {
  const accessToken = await getFirebaseAccessToken(env);
  const projectId = env.FIREBASE_PROJECT_ID;

  const query = {
    structuredQuery: {
      from: [{ collectionId: 'notifications' }],
      orderBy: [{ field: { fieldPath: 'timestamp' }, direction: 'DESCENDING' }],
      limit: 50
    }
  };

  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:runQuery`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(query)
    }
  );

  if (!response.ok) {
    throw new Error(`Error al listar notificaciones: ${response.status}`);
  }

  const results = await response.json() as Array<{
    document?: {
      fields: {
        type: { stringValue: string };
        title: { stringValue: string };
        body: { stringValue: string };
        timestamp: { timestampValue: string };
      };
    };
  }>;

  return results
    .filter(r => r.document)
    .map(r => ({
      type: r.document!.fields.type.stringValue,
      title: r.document!.fields.title.stringValue,
      body: r.document!.fields.body.stringValue,
      timestamp: r.document!.fields.timestamp.timestampValue
    }));
}

// ============================================================
// Firestore: Conversaciones
// ============================================================

// Carga el historial de conversacion desde Firestore
export async function loadConversation(
  conversationId: string,
  env: Env
): Promise<Array<{ role: string; content: string }>> {
  const accessToken = await getFirebaseAccessToken(env);
  const projectId = env.FIREBASE_PROJECT_ID;

  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/chat_history/${conversationId}`,
    {
      headers: { Authorization: `Bearer ${accessToken}` }
    }
  );

  if (!response.ok) {
    // Si no existe, devolver array vacio
    return [];
  }

  const data = await response.json() as {
    fields?: {
      messages?: {
        arrayValue?: {
          values?: Array<{
            mapValue?: {
              fields: {
                role: { stringValue: string };
                content: { stringValue: string };
              };
            };
          }>;
        };
      };
    };
  };

  const values = data.fields?.messages?.arrayValue?.values || [];

  return values
    .filter(v => v.mapValue)
    .map(v => ({
      role: v.mapValue!.fields.role.stringValue,
      content: v.mapValue!.fields.content.stringValue
    }));
}

// Guarda el historial de conversacion en Firestore
export async function saveConversation(
  conversationId: string,
  messages: Array<{ role: string; content: string }>,
  env: Env
): Promise<void> {
  const accessToken = await getFirebaseAccessToken(env);
  const projectId = env.FIREBASE_PROJECT_ID;

  // Mantener solo los ultimos 10 mensajes
  const recentMessages = messages.slice(-10);

  const document = {
    fields: {
      messages: {
        arrayValue: {
          values: recentMessages.map(m => ({
            mapValue: {
              fields: {
                role: { stringValue: m.role },
                content: { stringValue: m.content }
              }
            }
          }))
        }
      },
      updatedAt: { timestampValue: new Date().toISOString() }
    }
  };

  await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/chat_history/${conversationId}`,
    {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(document)
    }
  );
}

// ============================================================
// Utilidades
// ============================================================

function base64urlEncode(str: string): string {
  const encoder = new TextEncoder();
  const bytes = encoder.encode(str);
  let binary = '';
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}
