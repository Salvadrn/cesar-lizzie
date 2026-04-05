// ============================================================
// Tipos TypeScript para el Worker de JARVIS
// ============================================================

export interface Env {
  ANTHROPIC_API_KEY: string;
  FIREBASE_SERVICE_ACCOUNT_KEY: string;
  FIREBASE_PROJECT_ID: string;
  JARVIS_API_KEY: string;
  GOOGLE_CLIENT_ID: string;
  GOOGLE_CLIENT_SECRET: string;
  GOOGLE_REFRESH_TOKEN: string;
  NOTION_API_KEY: string;
  ADAPTAI_API_URL: string;
  ADAPTAI_API_KEY: string;
}

export interface ChatRequest {
  message: string;
  conversationId?: string;
  source?: 'pwa' | 'alexa' | 'robot' | 'patient';
  userId?: string;
  context?: {
    time: string;
    timezone: string;
  };
}

export interface ChatResponse {
  response: string;
  conversationId: string;
  actions: ActionResult[];
}

export interface ActionResult {
  tool: string;
  status: 'success' | 'error';
  summary: string;
}

export interface NotifyRequest {
  type: 'calendar' | 'email' | 'files' | 'backup' | 'alert';
  title: string;
  body: string;
  priority: 'high' | 'normal' | 'low';
}

// Tipos de la API de Claude
export interface ClaudeMessage {
  role: 'user' | 'assistant';
  content: ClaudeContent[] | string;
}

export interface ClaudeContent {
  type: 'text' | 'tool_use' | 'tool_result';
  text?: string;
  id?: string;
  name?: string;
  input?: Record<string, unknown>;
  tool_use_id?: string;
  content?: string;
  is_error?: boolean;
}

export interface ClaudeResponse {
  id: string;
  content: ClaudeContent[];
  stop_reason: 'end_turn' | 'tool_use' | 'max_tokens';
  usage: { input_tokens: number; output_tokens: number };
}

// Tipos de Google
export interface CalendarEvent {
  id: string;
  summary: string;
  start: { dateTime?: string; date?: string };
  end: { dateTime?: string; date?: string };
  description?: string;
  location?: string;
}

export interface GmailMessage {
  id: string;
  threadId: string;
  snippet: string;
  payload?: {
    headers: Array<{ name: string; value: string }>;
    body?: { data?: string };
    parts?: Array<{ mimeType: string; body: { data?: string } }>;
  };
}

// Tipo para la definicion de herramientas de Claude
export interface ClaudeTool {
  name: string;
  description: string;
  input_schema: {
    type: 'object';
    properties: Record<string, unknown>;
    required?: string[];
  };
}
