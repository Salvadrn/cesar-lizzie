// ============================================================
// Punto de entrada del Cloudflare Worker de JARVIS
// Router principal con CORS, autenticacion y rate limiting
// ============================================================

import type { Env, ChatRequest, NotifyRequest } from './types';
import { CHAT_SOURCES } from './types';
import { chat } from './chat';
import { sendPushNotification, listNotifications } from './notifications';

const PROD_ORIGINS = [
  'https://jarvis.pages.dev',
  'https://jarvis-ekp.pages.dev',
];
const DEV_ORIGINS = [
  'http://localhost:8080',
  'http://localhost:3000',
];
const MAX_CHAT_MESSAGE_LENGTH = 4000;

function getAllowedOrigins(env: Env): string[] {
  const fromEnv = (env.ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  const isProd = env.ENVIRONMENT === 'production';
  return isProd
    ? [...PROD_ORIGINS, ...fromEnv]
    : [...PROD_ORIGINS, ...DEV_ORIGINS, ...fromEnv];
}

// Rate limiting en memoria (se reinicia en cada deploy)
const rateLimitMap = new Map<string, { count: number; resetTime: number }>();
const RATE_LIMIT_MAX = 30;
const RATE_LIMIT_WINDOW = 60000; // 1 minuto

// Verifica el rate limiting por IP
function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const entry = rateLimitMap.get(ip);

  if (!entry || now > entry.resetTime) {
    rateLimitMap.set(ip, { count: 1, resetTime: now + RATE_LIMIT_WINDOW });
    return true;
  }

  if (entry.count >= RATE_LIMIT_MAX) {
    return false;
  }

  entry.count++;
  return true;
}

// Builds CORS response headers. Only echoes the Origin header when the
// origin is explicitly allow-listed; otherwise no Access-Control-Allow-Origin
// is set and the browser blocks the response. Never falls back to "*".
function getCorsHeaders(origin: string | null, env: Env): Record<string, string> {
  const headers: Record<string, string> = {
    'Vary': 'Origin',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400'
  };

  if (origin && getAllowedOrigins(env).includes(origin)) {
    headers['Access-Control-Allow-Origin'] = origin;
  }

  return headers;
}

function jsonResponse(
  data: unknown,
  status: number,
  origin: string | null,
  env: Env
): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...getCorsHeaders(origin, env)
    }
  });
}

// Verifica la autenticacion con API key
function authenticate(request: Request, env: Env): boolean {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader) return false;

  const token = authHeader.replace('Bearer ', '');
  return token === env.JARVIS_API_KEY;
}

// Router principal del Worker
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const origin = request.headers.get('Origin');
    const clientIP = request.headers.get('CF-Connecting-IP') || 'unknown';

    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: getCorsHeaders(origin, env)
      });
    }

    if (!checkRateLimit(clientIP)) {
      return jsonResponse(
        { error: 'Demasiadas solicitudes. Intenta de nuevo en un momento.' },
        429,
        origin,
        env
      );
    }

    try {
      if (url.pathname === '/api/health' && request.method === 'GET') {
        return jsonResponse({
          status: 'ok',
          version: '1.0.0',
          timestamp: new Date().toISOString()
        }, 200, origin, env);
      }

      if (url.pathname === '/auth/callback' && request.method === 'GET') {
        return await handleOAuthCallback(url, env, origin);
      }

      if (!authenticate(request, env)) {
        return jsonResponse(
          { error: 'No autorizado. Verifica tu API key.' },
          401,
          origin,
          env
        );
      }

      // POST /api/chat/patient — Modo paciente (acompanante medico).
      // Source is fixed server-side; the body is not allowed to override it.
      if (url.pathname === '/api/chat/patient' && request.method === 'POST') {
        const body = await request.json() as ChatRequest;
        const validation = validateChatBody(body);
        if (validation) return jsonResponse({ error: validation }, 400, origin, env);

        const result = await chat(
          body.message,
          body.conversationId,
          body.context,
          env,
          'patient'
        );

        return jsonResponse(result, 200, origin, env);
      }

      if (url.pathname === '/api/chat' && request.method === 'POST') {
        const body = await request.json() as ChatRequest;
        const validation = validateChatBody(body);
        if (validation) return jsonResponse({ error: validation }, 400, origin, env);

        const source = body.source && CHAT_SOURCES.includes(body.source)
          ? body.source
          : 'pwa';

        const result = await chat(
          body.message,
          body.conversationId,
          body.context,
          env,
          source
        );

        return jsonResponse(result, 200, origin, env);
      }

      if (url.pathname === '/api/notify' && request.method === 'POST') {
        const body = await request.json() as NotifyRequest;

        if (!body.title || !body.body) {
          return jsonResponse(
            { error: 'Se requiere title y body.' },
            400,
            origin,
            env
          );
        }

        const result = await sendPushNotification(
          body.title,
          body.body,
          body.priority || 'normal',
          env
        );

        return jsonResponse({ status: 'ok', result }, 200, origin, env);
      }

      if (url.pathname === '/api/notifications' && request.method === 'GET') {
        const notifications = await listNotifications(env);
        return jsonResponse({ notifications }, 200, origin, env);
      }

      return jsonResponse({ error: 'Ruta no encontrada.' }, 404, origin, env);

    } catch (error) {
      console.error('Error en el worker:', error);
      // Don't leak internal error messages to the client; log and return generic.
      return jsonResponse(
        { error: 'Error interno del servidor' },
        500,
        origin,
        env
      );
    }
  }
};

function validateChatBody(body: ChatRequest): string | null {
  if (!body || typeof body.message !== 'string' || body.message.trim() === '') {
    return 'El mensaje no puede estar vacío.';
  }
  if (body.message.length > MAX_CHAT_MESSAGE_LENGTH) {
    return `El mensaje supera el largo máximo (${MAX_CHAT_MESSAGE_LENGTH} caracteres).`;
  }
  return null;
}

// ============================================================
// OAuth callback de Google
// ============================================================
async function handleOAuthCallback(
  url: URL,
  env: Env,
  origin: string | null
): Promise<Response> {
  const code = url.searchParams.get('code');
  const error = url.searchParams.get('error');

  if (error) {
    // Avoid reflecting attacker-controlled query params back into HTML.
    return new Response(htmlPage('Error', 'Error de autenticación.'), {
      status: 400,
      headers: { 'Content-Type': 'text/html', ...getCorsHeaders(origin, env) }
    });
  }

  if (!code) {
    return new Response(htmlPage('Error', 'No se recibió código de autorización.'), {
      status: 400,
      headers: { 'Content-Type': 'text/html', ...getCorsHeaders(origin, env) }
    });
  }

  try {
    // Intercambiar code por tokens
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code,
        client_id: env.GOOGLE_CLIENT_ID,
        client_secret: env.GOOGLE_CLIENT_SECRET,
        redirect_uri: `${url.origin}/auth/callback`,
        grant_type: 'authorization_code'
      })
    });

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text();
      throw new Error(`Error al obtener tokens: ${errorText}`);
    }

    const tokens = await tokenResponse.json() as {
      access_token: string;
      refresh_token?: string;
      expires_in: number;
    };

    // Mostrar el refresh_token para que el usuario lo configure como secret.
    // Escape the token before injecting into HTML to avoid XSS if Google ever
    // returns characters that look like markup (defensive, low-risk).
    const refreshInfo = tokens.refresh_token
      ? `<p><strong>Refresh Token:</strong></p>
         <code style="word-break:break-all;background:#1a2a3a;padding:12px;display:block;border-radius:8px;font-size:12px;">${escapeHtml(tokens.refresh_token)}</code>
         <p style="margin-top:12px;color:#ffd700;">⚠️ Guarda este token como secret en Cloudflare Workers:</p>
         <code>wrangler secret put GOOGLE_REFRESH_TOKEN</code>`
      : '<p style="color:#ff3333;">No se recibió refresh_token. Asegúrate de usar prompt=consent y access_type=offline.</p>';

    return new Response(
      htmlPage('JARVIS conectado a Google', refreshInfo),
      {
        status: 200,
        headers: { 'Content-Type': 'text/html' }
      }
    );
  } catch (err) {
    console.error('OAuth callback failed:', err);
    return new Response(
      htmlPage('Error', 'No se pudo completar la autenticación.'),
      {
        status: 500,
        headers: { 'Content-Type': 'text/html' }
      }
    );
  }
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

// Genera una pagina HTML simple con estilo JARVIS
function htmlPage(title: string, content: string): string {
  return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>JARVIS — ${title}</title>
  <style>
    body {
      font-family: 'Inter', sans-serif;
      background: #0a0a1a;
      color: #fff;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      padding: 20px;
    }
    .container {
      max-width: 500px;
      text-align: center;
      background: rgba(13,33,55,0.8);
      border: 1px solid rgba(0,212,255,0.2);
      border-radius: 16px;
      padding: 40px;
    }
    h1 {
      color: #00d4ff;
      font-size: 1.5rem;
      margin-bottom: 16px;
    }
    p { color: rgba(255,255,255,0.7); line-height: 1.6; }
    code { color: #00d4ff; }
  </style>
</head>
<body>
  <div class="container">
    <h1>${title}</h1>
    ${content}
  </div>
</body>
</html>`;
}
