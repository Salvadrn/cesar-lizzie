// ============================================================
// Integracion con Google Calendar API v3 y Gmail API v1
// Usa OAuth2 con refresh token para autenticacion
// ============================================================

import type { Env } from './types';

// Cache del access token para evitar refrescos innecesarios
let cachedAccessToken: string | null = null;
let tokenExpiresAt = 0;

// Parametros para crear un evento
interface CreateEventParams {
  title: string;
  date: string;
  startTime: string;
  endTime?: string;
  description?: string;
}

// Obtiene un access token valido usando el refresh token
export async function getAccessToken(env: Env): Promise<string> {
  // Usar token cacheado si aun es valido (con 5 min de margen)
  if (cachedAccessToken && Date.now() < tokenExpiresAt - 300000) {
    return cachedAccessToken;
  }

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: env.GOOGLE_CLIENT_ID,
      client_secret: env.GOOGLE_CLIENT_SECRET,
      refresh_token: env.GOOGLE_REFRESH_TOKEN,
      grant_type: 'refresh_token'
    })
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Error al obtener token de Google: ${error}`);
  }

  const data = await response.json() as { access_token: string; expires_in: number };
  cachedAccessToken = data.access_token;
  // Cachear por 50 minutos (los tokens duran 60 min)
  tokenExpiresAt = Date.now() + 50 * 60 * 1000;

  return cachedAccessToken;
}

// ============================================================
// GOOGLE CALENDAR
// ============================================================

// Lista eventos del calendario para una fecha o rango de fechas
export async function listEvents(date: string, days: number, env: Env): Promise<string> {
  const token = await getAccessToken(env);

  // Calcular rango de fechas
  const startDate = new Date(`${date}T00:00:00`);
  const endDate = new Date(startDate);
  endDate.setDate(endDate.getDate() + days);

  const params = new URLSearchParams({
    timeMin: startDate.toISOString(),
    timeMax: endDate.toISOString(),
    orderBy: 'startTime',
    singleEvents: 'true',
    maxResults: '20'
  });

  const response = await fetch(
    `https://www.googleapis.com/calendar/v3/calendars/primary/events?${params}`,
    {
      headers: { Authorization: `Bearer ${token}` }
    }
  );

  if (!response.ok) {
    throw new Error(`Error al consultar calendario: ${response.status}`);
  }

  const data = await response.json() as { items: Array<{
    id: string;
    summary: string;
    start: { dateTime?: string; date?: string };
    end: { dateTime?: string; date?: string };
    location?: string;
    description?: string;
  }> };

  const events = data.items || [];

  if (events.length === 0) {
    return `No hay eventos programados para ${days === 1 ? 'ese día' : `los próximos ${days} días`}.`;
  }

  // Formatear eventos para que Claude los presente
  const formatted = events.map((event, i) => {
    const start = event.start.dateTime || event.start.date || '';
    let timeStr = '';

    if (event.start.dateTime) {
      const d = new Date(event.start.dateTime);
      timeStr = d.toLocaleTimeString('es-MX', {
        timeZone: 'America/Mexico_City',
        hour: '2-digit',
        minute: '2-digit'
      });
    } else {
      timeStr = 'Todo el día';
    }

    let line = `${i + 1}. ${timeStr} — ${event.summary || 'Sin título'}`;
    if (event.location) line += ` (📍 ${event.location})`;
    return line;
  });

  const dateStr = new Date(date).toLocaleDateString('es-MX', {
    weekday: 'long',
    day: 'numeric',
    month: 'long'
  });

  return `Eventos para ${dateStr}:\n${formatted.join('\n')}`;
}

// Crea un nuevo evento en el calendario
export async function createEvent(params: CreateEventParams, env: Env): Promise<string> {
  const token = await getAccessToken(env);

  // Construir horarios del evento
  const startDateTime = `${params.date}T${params.startTime}:00`;
  const endTime = params.endTime || (() => {
    // Si no se especifica hora fin, agregar 1 hora
    const [h, m] = params.startTime.split(':').map(Number);
    return `${String(h + 1).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
  })();
  const endDateTime = `${params.date}T${endTime}:00`;

  const eventBody = {
    summary: params.title,
    description: params.description || '',
    start: {
      dateTime: new Date(startDateTime).toISOString(),
      timeZone: 'America/Mexico_City'
    },
    end: {
      dateTime: new Date(endDateTime).toISOString(),
      timeZone: 'America/Mexico_City'
    }
  };

  const response = await fetch(
    'https://www.googleapis.com/calendar/v3/calendars/primary/events',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(eventBody)
    }
  );

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Error al crear evento: ${error}`);
  }

  const created = await response.json() as { summary: string; start: { dateTime: string } };

  const eventDate = new Date(created.start.dateTime);
  const timeStr = eventDate.toLocaleTimeString('es-MX', {
    timeZone: 'America/Mexico_City',
    hour: '2-digit',
    minute: '2-digit'
  });

  return `Evento "${created.summary}" creado exitosamente para las ${timeStr}.`;
}

// Elimina un evento del calendario
export async function deleteEvent(eventId: string, env: Env): Promise<string> {
  const token = await getAccessToken(env);

  const response = await fetch(
    `https://www.googleapis.com/calendar/v3/calendars/primary/events/${eventId}`,
    {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` }
    }
  );

  if (!response.ok && response.status !== 204) {
    throw new Error(`Error al eliminar evento: ${response.status}`);
  }

  return 'Evento eliminado correctamente del calendario.';
}

// ============================================================
// GMAIL
// ============================================================

// Lista correos no leidos
export async function listUnread(maxResults: number, query: string, env: Env): Promise<string> {
  const token = await getAccessToken(env);

  const searchQuery = query ? `is:unread ${query}` : 'is:unread';
  const params = new URLSearchParams({
    q: searchQuery,
    maxResults: String(maxResults)
  });

  // Obtener lista de IDs de mensajes
  const listResponse = await fetch(
    `https://gmail.googleapis.com/gmail/v1/users/me/messages?${params}`,
    {
      headers: { Authorization: `Bearer ${token}` }
    }
  );

  if (!listResponse.ok) {
    throw new Error(`Error al consultar correos: ${listResponse.status}`);
  }

  const listData = await listResponse.json() as {
    messages?: Array<{ id: string; threadId: string }>;
    resultSizeEstimate: number;
  };

  const messages = listData.messages || [];

  if (messages.length === 0) {
    return 'No hay correos sin leer.';
  }

  // Obtener detalles de cada mensaje
  const details = await Promise.all(
    messages.slice(0, Math.min(maxResults, 10)).map(async (msg) => {
      const msgResponse = await fetch(
        `https://gmail.googleapis.com/gmail/v1/users/me/messages/${msg.id}?format=metadata&metadataHeaders=From&metadataHeaders=Subject&metadataHeaders=Date`,
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      );

      if (!msgResponse.ok) return null;

      const msgData = await msgResponse.json() as {
        id: string;
        snippet: string;
        payload: { headers: Array<{ name: string; value: string }> };
      };

      const headers = msgData.payload.headers;
      const from = headers.find(h => h.name === 'From')?.value || 'Desconocido';
      const subject = headers.find(h => h.name === 'Subject')?.value || 'Sin asunto';
      const date = headers.find(h => h.name === 'Date')?.value || '';

      // Extraer solo el nombre del remitente
      const fromName = from.replace(/<.*>/, '').trim() || from;

      return { id: msg.id, from: fromName, subject, date, snippet: msgData.snippet };
    })
  );

  const validDetails = details.filter(Boolean);
  const formatted = validDetails.map((d, i) => {
    return `${i + 1}. De: ${d!.from}\n   Asunto: ${d!.subject}`;
  });

  return `${validDetails.length} correo(s) sin leer:\n${formatted.join('\n')}`;
}

// Lee el contenido completo de un correo
export async function readEmail(messageId: string, env: Env): Promise<string> {
  const token = await getAccessToken(env);

  const response = await fetch(
    `https://gmail.googleapis.com/gmail/v1/users/me/messages/${messageId}?format=full`,
    {
      headers: { Authorization: `Bearer ${token}` }
    }
  );

  if (!response.ok) {
    throw new Error(`Error al leer correo: ${response.status}`);
  }

  const data = await response.json() as {
    payload: {
      headers: Array<{ name: string; value: string }>;
      body?: { data?: string };
      parts?: Array<{ mimeType: string; body: { data?: string } }>;
    };
    snippet: string;
  };

  const headers = data.payload.headers;
  const from = headers.find(h => h.name === 'From')?.value || 'Desconocido';
  const subject = headers.find(h => h.name === 'Subject')?.value || 'Sin asunto';
  const date = headers.find(h => h.name === 'Date')?.value || '';

  // Extraer el cuerpo del correo
  let body = '';

  if (data.payload.body?.data) {
    body = base64urlDecode(data.payload.body.data);
  } else if (data.payload.parts) {
    // Buscar parte de texto plano
    const textPart = data.payload.parts.find(p => p.mimeType === 'text/plain');
    if (textPart?.body?.data) {
      body = base64urlDecode(textPart.body.data);
    } else {
      // Fallback al snippet
      body = data.snippet;
    }
  } else {
    body = data.snippet;
  }

  // Limitar longitud del cuerpo para la respuesta
  if (body.length > 1000) {
    body = body.substring(0, 1000) + '... (truncado)';
  }

  return `De: ${from}\nAsunto: ${subject}\nFecha: ${date}\n\n${body}`;
}

// Envia un correo electronico
export async function sendEmail(to: string, subject: string, body: string, env: Env): Promise<string> {
  const token = await getAccessToken(env);

  // Construir mensaje RFC 2822
  const emailLines = [
    `To: ${to}`,
    `Subject: ${subject}`,
    'MIME-Version: 1.0',
    'Content-Type: text/plain; charset=UTF-8',
    '',
    body
  ];

  const rawEmail = emailLines.join('\r\n');
  const encoded = base64urlEncode(rawEmail);

  const response = await fetch(
    'https://gmail.googleapis.com/gmail/v1/users/me/messages/send',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ raw: encoded })
    }
  );

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Error al enviar correo: ${error}`);
  }

  return `Correo enviado exitosamente a ${to} con asunto "${subject}".`;
}

// ============================================================
// Utilidades de codificacion
// ============================================================

// Codifica una cadena a base64url
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

// Decodifica una cadena de base64url
function base64urlDecode(str: string): string {
  const base64 = str.replace(/-/g, '+').replace(/_/g, '/');
  const padded = base64 + '='.repeat((4 - base64.length % 4) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return new TextDecoder().decode(bytes);
}
