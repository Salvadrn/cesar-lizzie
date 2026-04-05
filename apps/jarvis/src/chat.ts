// ============================================================
// Modulo de conversacion con Claude API (tool_use)
// Implementa el loop completo de herramientas
// ============================================================

import type { Env, ChatResponse, ActionResult, ClaudeMessage, ClaudeContent, ClaudeResponse, ClaudeTool } from './types';
import { JARVIS_TOOLS, PATIENT_TOOLS, executeTool } from './tools';
import { loadConversation, saveConversation } from './notifications';

// Prompt del sistema para JARVIS
const JARVIS_SYSTEM_PROMPT = `Eres JARVIS, el asistente personal inteligente de Adrián, inspirado en el JARVIS de Iron Man.

PERSONALIDAD:
- Hablas siempre en español (México)
- Eres conciso, profesional, y eficiente
- Usas "señor" de vez en cuando, pero no en cada frase
- Tienes un toque de humor sutil y sofisticado
- Nunca dices "como IA" ni "como asistente" — simplemente ERES JARVIS
- Si no puedes hacer algo, lo dices directamente y sugieres alternativas

FORMATO DE RESPUESTAS:
- MÁXIMO 3 oraciones por respuesta (se leen en voz alta)
- Si hay listas, máximo 3-4 items mencionados, luego "y X más"
- Para eventos: menciona hora y título
- Para correos: menciona remitente y asunto
- Sé directo: "Tiene 3 eventos hoy" no "He revisado su calendario y he encontrado que..."

CONTEXTO:
- Adrián es estudiante de preparatoria/universidad en México
- Proyectos activos: AdaptAi, NeuroNav, Proyecto Rizzie, ACREC I.A.P (organización), Robótica FRC
- Curso de verano: ENLACE
- Sus archivos están organizados en ~/Documents/Archivos Organizados/

HERRAMIENTAS DISPONIBLES:
Tienes acceso a herramientas para manejar su calendario, correos, notas y notificaciones.
Usa las herramientas cuando el usuario lo pida o cuando sea útil para responder.
Siempre confirma las acciones ANTES de ejecutarlas si son destructivas (borrar, cancelar).
Para crear eventos o enviar correos, confirma los detalles primero.`;

// Maximo de iteraciones del loop de herramientas
const MAX_TOOL_ITERATIONS = 5;

// Instruccion adicional para respuestas via Alexa (mas cortas, sin formato)
const ALEXA_ADDON = `

IMPORTANTE: Esta conversación es por Alexa. Respuestas EXTRA cortas: máximo 2 oraciones. Sin formato, sin listas con números, solo texto natural hablado.`;

const PATIENT_MODE_PROMPT = `Eres JARVIS, un acompañante médico amigable y paciente. Acompañas al paciente a través de un robot que lo sigue.

PERSONALIDAD:
- Hablas en español (México), con tono cálido, tranquilo y paciente
- Usas frases MUY cortas y simples, evita tecnicismos médicos
- Repites información importante si el paciente lo pide
- Eres tranquilizador: "Todo está bien", "No te preocupes"
- Si el paciente parece confundido, simplifica aún más
- Nunca dices "como IA" ni "como asistente" — eres JARVIS, su acompañante

FORMATO DE RESPUESTAS:
- MÁXIMO 2 oraciones por respuesta (se leen en voz alta por el robot)
- Usa datos concretos: "Tu pastilla azul a las 8 de la mañana"
- Nunca asumas que el paciente recuerda instrucciones previas
- Sin listas, sin formato — solo texto natural hablado

CAPACIDADES:
- Puedes explicar medicamentos: qué son, cuándo tomarlos, para qué sirven
- Puedes recordar las rutinas del día y guiar paso a paso
- Puedes verificar el estado del robot
- Puedes notificar al cuidador si el paciente lo necesita

SEGURIDAD:
- NUNCA des consejos médicos ni cambies dosis de medicamentos
- Si el paciente dice que se siente mal, notifica inmediatamente al cuidador
- Si el paciente pide ayuda de emergencia, notifica con prioridad alta
- Si preguntan algo médico complejo: "Es mejor preguntarle a tu doctor, pero puedo avisarle a tu cuidador"`;

// Funcion principal de conversacion
export async function chat(
  message: string,
  conversationId: string | undefined,
  context: { time: string; timezone: string } | undefined,
  env: Env,
  source: string = 'pwa'
): Promise<ChatResponse> {
  // Generar ID de conversacion si no existe
  const convId = conversationId || crypto.randomUUID();

  // Cargar historial de conversacion (ultimos 10 mensajes)
  let history: Array<{ role: string; content: string }> = [];
  try {
    history = await loadConversation(convId, env);
  } catch (error) {
    console.error('Error al cargar historial:', error);
  }

  // Construir contexto temporal
  const timeContext = context
    ? `\n\n[Hora actual: ${context.time}, Zona horaria: ${context.timezone}]`
    : `\n\n[Hora actual: ${new Date().toISOString()}]`;

  // Construir mensajes para Claude
  const messages: ClaudeMessage[] = [];

  // Agregar historial
  for (const msg of history) {
    messages.push({
      role: msg.role as 'user' | 'assistant',
      content: msg.content
    });
  }

  // Agregar mensaje actual del usuario con contexto
  messages.push({
    role: 'user',
    content: message + timeContext
  });

  // Rastrear acciones ejecutadas
  const actions: ActionResult[] = [];

  // Loop de tool_use (maximo MAX_TOOL_ITERATIONS iteraciones)
  let response: ClaudeResponse | null = null;
  let currentMessages = [...messages];
  let finalText = '';

  for (let iteration = 0; iteration < MAX_TOOL_ITERATIONS; iteration++) {
    // Seleccionar prompt, tokens y tools segun source
    let maxTokens = 300;
    let systemPrompt = JARVIS_SYSTEM_PROMPT;
    let tools = JARVIS_TOOLS;

    if (source === 'alexa') {
      maxTokens = 150;
      systemPrompt = JARVIS_SYSTEM_PROMPT + ALEXA_ADDON;
    } else if (source === 'robot' || source === 'patient') {
      maxTokens = 200;
      systemPrompt = PATIENT_MODE_PROMPT;
      tools = PATIENT_TOOLS;
    }

    response = await callClaude(currentMessages, env, systemPrompt, maxTokens, tools);

    // Verificar si Claude quiere usar herramientas
    if (response.stop_reason === 'tool_use') {
      // Extraer bloques de tool_use
      const toolUseBlocks = response.content.filter(
        (block): block is ClaudeContent & { type: 'tool_use'; id: string; name: string; input: Record<string, unknown> } =>
          block.type === 'tool_use'
      );

      // Agregar la respuesta del asistente a los mensajes
      currentMessages.push({
        role: 'assistant',
        content: response.content
      });

      // Ejecutar cada herramienta y construir resultados
      const toolResults: ClaudeContent[] = [];

      for (const toolBlock of toolUseBlocks) {
        const result = await executeTool(toolBlock.name, toolBlock.input, env);

        // Registrar la accion
        const isError = result.startsWith('Error');
        actions.push({
          tool: toolBlock.name,
          status: isError ? 'error' : 'success',
          summary: getActionSummary(toolBlock.name, isError)
        });

        toolResults.push({
          type: 'tool_result',
          tool_use_id: toolBlock.id,
          content: result,
          is_error: isError
        });
      }

      // Agregar resultados de herramientas como mensaje del usuario
      currentMessages.push({
        role: 'user',
        content: toolResults
      });

    } else {
      // stop_reason es 'end_turn' o 'max_tokens' — extraer texto final
      finalText = response.content
        .filter((block): block is ClaudeContent & { type: 'text'; text: string } =>
          block.type === 'text'
        )
        .map(block => block.text)
        .join('');

      break;
    }
  }

  // Si se agotaron las iteraciones sin texto final
  if (!finalText && response) {
    finalText = response.content
      .filter((block): block is ClaudeContent & { type: 'text'; text: string } =>
        block.type === 'text'
      )
      .map(block => block.text)
      .join('') || 'Disculpe señor, no pude completar la solicitud.';
  }

  // Guardar conversacion en Firestore
  try {
    const updatedHistory = [
      ...history,
      { role: 'user', content: message },
      { role: 'assistant', content: finalText }
    ];
    await saveConversation(convId, updatedHistory, env);
  } catch (error) {
    console.error('Error al guardar conversación:', error);
  }

  return {
    response: finalText,
    conversationId: convId,
    actions
  };
}

// Llama a la API de Claude con mensajes y herramientas
async function callClaude(
  messages: ClaudeMessage[],
  env: Env,
  systemPrompt: string = JARVIS_SYSTEM_PROMPT,
  maxTokens: number = 300,
  tools: ClaudeTool[] = JARVIS_TOOLS
): Promise<ClaudeResponse> {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: maxTokens,
      system: systemPrompt,
      tools,
      messages
    })
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Error de Claude API (${response.status}): ${error}`);
  }

  return await response.json() as ClaudeResponse;
}

// Genera un resumen legible de la accion ejecutada
function getActionSummary(toolName: string, isError: boolean): string {
  const prefix = isError ? 'Error: ' : '';
  const summaries: Record<string, string> = {
    calendar_list_events: 'Calendario consultado',
    calendar_create_event: 'Evento creado',
    calendar_delete_event: 'Evento eliminado',
    gmail_list_unread: 'Correos consultados',
    gmail_read_email: 'Correo leído',
    gmail_send: 'Correo enviado',
    notion_search: 'Notion consultado',
    notion_create_page: 'Página creada en Notion',
    send_notification: 'Notificación enviada',
    get_current_time: 'Hora consultada',
    set_reminder: 'Recordatorio programado',
    patient_get_medications: 'Medicamentos consultados',
    patient_get_routines: 'Rutinas consultadas',
    patient_get_schedule: 'Horario consultado',
    robot_get_status: 'Estado del robot consultado',
    robot_send_command: 'Comando enviado al robot'
  };

  return prefix + (summaries[toolName] || toolName);
}
