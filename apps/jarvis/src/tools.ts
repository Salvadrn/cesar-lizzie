// ============================================================
// Definicion de herramientas (tools) de JARVIS para Claude API
// ============================================================

import type { ClaudeTool, Env } from './types';
import { listEvents, createEvent, deleteEvent, listUnread, readEmail, sendEmail } from './google';
import { searchNotion, createPage } from './notion';
import { sendPushNotification, saveNotification } from './notifications';
import { getPatientMedications, getPatientRoutines, getPatientSchedule, getRobotStatus, sendRobotCommand } from './adaptai';

// Todas las herramientas disponibles para Claude
export const JARVIS_TOOLS: ClaudeTool[] = [
  // === GOOGLE CALENDAR ===
  {
    name: 'calendar_list_events',
    description: 'Listar eventos del calendario de Adrián para una fecha o rango de fechas',
    input_schema: {
      type: 'object',
      properties: {
        date: { type: 'string', description: 'Fecha en formato YYYY-MM-DD. Si no se especifica, usar hoy' },
        days: { type: 'number', description: 'Número de días a consultar desde date. Default 1' }
      }
    }
  },
  {
    name: 'calendar_create_event',
    description: 'Crear un nuevo evento en el calendario de Adrián',
    input_schema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: 'Título del evento' },
        date: { type: 'string', description: 'Fecha YYYY-MM-DD' },
        startTime: { type: 'string', description: 'Hora inicio HH:MM' },
        endTime: { type: 'string', description: 'Hora fin HH:MM' },
        description: { type: 'string', description: 'Descripción opcional' }
      },
      required: ['title', 'date', 'startTime']
    }
  },
  {
    name: 'calendar_delete_event',
    description: 'Eliminar un evento del calendario',
    input_schema: {
      type: 'object',
      properties: {
        eventId: { type: 'string', description: 'ID del evento a eliminar' }
      },
      required: ['eventId']
    }
  },

  // === GMAIL ===
  {
    name: 'gmail_list_unread',
    description: 'Listar correos no leídos de Adrián, opcionalmente filtrados',
    input_schema: {
      type: 'object',
      properties: {
        maxResults: { type: 'number', description: 'Máximo de correos. Default 10' },
        query: { type: 'string', description: 'Filtro de búsqueda opcional (ej: "from:profesor")' }
      }
    }
  },
  {
    name: 'gmail_read_email',
    description: 'Leer el contenido completo de un correo específico',
    input_schema: {
      type: 'object',
      properties: {
        messageId: { type: 'string', description: 'ID del mensaje' }
      },
      required: ['messageId']
    }
  },
  {
    name: 'gmail_send',
    description: 'Enviar un correo electrónico en nombre de Adrián. SIEMPRE confirmar con el usuario antes de enviar.',
    input_schema: {
      type: 'object',
      properties: {
        to: { type: 'string', description: 'Dirección de correo del destinatario' },
        subject: { type: 'string', description: 'Asunto del correo' },
        body: { type: 'string', description: 'Cuerpo del correo en texto plano' }
      },
      required: ['to', 'subject', 'body']
    }
  },

  // === NOTION ===
  {
    name: 'notion_search',
    description: 'Buscar páginas y documentos en el Notion de Adrián',
    input_schema: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'Texto a buscar' }
      },
      required: ['query']
    }
  },
  {
    name: 'notion_create_page',
    description: 'Crear una nueva página en Notion',
    input_schema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: 'Título de la página' },
        content: { type: 'string', description: 'Contenido en markdown' },
        parentId: { type: 'string', description: 'ID de la página padre. Opcional.' }
      },
      required: ['title', 'content']
    }
  },

  // === NOTIFICACIONES ===
  {
    name: 'send_notification',
    description: 'Enviar una notificación push al iPhone de Adrián',
    input_schema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: 'Título de la notificación' },
        body: { type: 'string', description: 'Cuerpo de la notificación' },
        priority: { type: 'string', enum: ['high', 'normal', 'low'], description: 'Prioridad' }
      },
      required: ['title', 'body']
    }
  },

  // === UTILIDADES ===
  {
    name: 'get_current_time',
    description: 'Obtener la hora y fecha actual en la zona horaria de Adrián (America/Mexico_City)',
    input_schema: {
      type: 'object',
      properties: {}
    }
  },
  {
    name: 'set_reminder',
    description: 'Programar un recordatorio para Adrián. Se enviará como push notification a la hora indicada.',
    input_schema: {
      type: 'object',
      properties: {
        message: { type: 'string', description: 'Texto del recordatorio' },
        datetime: { type: 'string', description: 'Fecha y hora ISO 8601 para el recordatorio' }
      },
      required: ['message', 'datetime']
    }
  }
];

// === ADAPT AI - TOOLS DE PACIENTE Y ROBOT ===
export const PATIENT_TOOLS: ClaudeTool[] = [
  {
    name: 'patient_get_medications',
    description: 'Obtener la lista de medicamentos del paciente con horarios y dosis',
    input_schema: {
      type: 'object',
      properties: {
        userId: { type: 'string', description: 'ID del paciente' }
      },
      required: ['userId']
    }
  },
  {
    name: 'patient_get_routines',
    description: 'Obtener todas las rutinas diarias del paciente (higiene, cocina, medicamentos, etc.)',
    input_schema: {
      type: 'object',
      properties: {
        userId: { type: 'string', description: 'ID del paciente' }
      },
      required: ['userId']
    }
  },
  {
    name: 'patient_get_schedule',
    description: 'Ver el horario de actividades de hoy del paciente y su estado (pendiente, en progreso, completada)',
    input_schema: {
      type: 'object',
      properties: {
        userId: { type: 'string', description: 'ID del paciente' }
      },
      required: ['userId']
    }
  },
  {
    name: 'robot_get_status',
    description: 'Obtener el estado actual del robot acompañante (batería, sensores, distancia al paciente)',
    input_schema: {
      type: 'object',
      properties: {
        robotId: { type: 'string', description: 'ID del robot' }
      },
      required: ['robotId']
    }
  },
  {
    name: 'robot_send_command',
    description: 'Enviar un comando al robot (iniciar seguimiento, pausar, detener, parada de emergencia)',
    input_schema: {
      type: 'object',
      properties: {
        robotId: { type: 'string', description: 'ID del robot' },
        command: { type: 'string', enum: ['start', 'stop', 'pause', 'resume', 'emergency_stop', 'reset'], description: 'Comando a enviar' }
      },
      required: ['robotId', 'command']
    }
  },
  // Incluir utilidades basicas
  {
    name: 'get_current_time',
    description: 'Obtener la hora y fecha actual en México',
    input_schema: {
      type: 'object',
      properties: {}
    }
  },
  {
    name: 'send_notification',
    description: 'Enviar una notificación al cuidador del paciente',
    input_schema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: 'Título de la notificación' },
        body: { type: 'string', description: 'Cuerpo de la notificación' },
        priority: { type: 'string', enum: ['high', 'normal', 'low'], description: 'Prioridad' }
      },
      required: ['title', 'body']
    }
  }
];

// Ejecuta una herramienta y devuelve el resultado como texto
export async function executeTool(
  name: string,
  input: Record<string, unknown>,
  env: Env
): Promise<string> {
  try {
    switch (name) {
      // Calendario
      case 'calendar_list_events': {
        const date = (input.date as string) || new Date().toISOString().split('T')[0];
        const days = (input.days as number) || 1;
        return await listEvents(date, days, env);
      }
      case 'calendar_create_event': {
        return await createEvent({
          title: input.title as string,
          date: input.date as string,
          startTime: input.startTime as string,
          endTime: input.endTime as string | undefined,
          description: input.description as string | undefined
        }, env);
      }
      case 'calendar_delete_event': {
        return await deleteEvent(input.eventId as string, env);
      }

      // Gmail
      case 'gmail_list_unread': {
        const maxResults = (input.maxResults as number) || 10;
        const query = (input.query as string) || '';
        return await listUnread(maxResults, query, env);
      }
      case 'gmail_read_email': {
        return await readEmail(input.messageId as string, env);
      }
      case 'gmail_send': {
        return await sendEmail(
          input.to as string,
          input.subject as string,
          input.body as string,
          env
        );
      }

      // Notion
      case 'notion_search': {
        return await searchNotion(input.query as string, env);
      }
      case 'notion_create_page': {
        return await createPage(
          input.title as string,
          input.content as string,
          input.parentId as string | undefined,
          env
        );
      }

      // Notificaciones
      case 'send_notification': {
        return await sendPushNotification(
          input.title as string,
          input.body as string,
          (input.priority as string) || 'normal',
          env
        );
      }

      // Utilidades
      case 'get_current_time': {
        const now = new Date();
        const mexicoTime = now.toLocaleString('es-MX', {
          timeZone: 'America/Mexico_City',
          weekday: 'long',
          year: 'numeric',
          month: 'long',
          day: 'numeric',
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit'
        });
        return `Fecha y hora actual en México: ${mexicoTime}`;
      }
      case 'set_reminder': {
        // Guardar recordatorio como notificacion programada
        await saveNotification('reminder', input.message as string, input.datetime as string, env);
        const reminderDate = new Date(input.datetime as string);
        const formatted = reminderDate.toLocaleString('es-MX', {
          timeZone: 'America/Mexico_City',
          dateStyle: 'medium',
          timeStyle: 'short'
        });
        return `Recordatorio programado para ${formatted}: "${input.message}"`;
      }

      // Adapt AI - Paciente
      case 'patient_get_medications': {
        return await getPatientMedications(input.userId as string, env);
      }
      case 'patient_get_routines': {
        return await getPatientRoutines(input.userId as string, env);
      }
      case 'patient_get_schedule': {
        return await getPatientSchedule(input.userId as string, env);
      }
      case 'robot_get_status': {
        return await getRobotStatus(input.robotId as string, env);
      }
      case 'robot_send_command': {
        return await sendRobotCommand(input.robotId as string, input.command as string, env);
      }

      default:
        return `Herramienta "${name}" no reconocida.`;
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Error desconocido';
    console.error(`Error ejecutando herramienta ${name}:`, error);
    return `Error al ejecutar ${name}: ${message}`;
  }
}
