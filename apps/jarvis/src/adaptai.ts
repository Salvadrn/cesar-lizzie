// ============================================================
// Integracion con el backend de Adapt AI (NestJS)
// Funciones para obtener datos del paciente y controlar el robot
// ============================================================

import type { Env } from './types';

// Llama al API de Adapt AI con autenticacion
async function adaptaiRequest(
  path: string,
  method: string,
  env: Env,
  body?: unknown
): Promise<string> {
  const url = `${env.ADAPTAI_API_URL || 'http://localhost:3001/api/v1'}/${path}`;

  const response = await fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${env.ADAPTAI_API_KEY}`
    },
    body: body ? JSON.stringify(body) : undefined
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Adapt AI API error (${response.status}): ${error}`);
  }

  return await response.text();
}

// Obtener medicamentos del paciente (rutinas de tipo medication)
export async function getPatientMedications(userId: string, env: Env): Promise<string> {
  try {
    const data = await adaptaiRequest(
      `routines?userId=${userId}&category=medication`,
      'GET',
      env
    );

    const routines = JSON.parse(data);
    if (!routines || routines.length === 0) {
      return 'El paciente no tiene medicamentos registrados actualmente.';
    }

    const meds = routines.map((r: any) => {
      const steps = r.steps?.map((s: any) => s.instructionSimple || s.instruction).join(', ') || '';
      const schedule = r.scheduleType === 'daily' ? 'diario'
        : r.scheduleType === 'weekly' ? 'semanal'
        : r.scheduleType || 'sin horario';
      return `- ${r.title} (${schedule}): ${steps}`;
    }).join('\n');

    return `Medicamentos del paciente:\n${meds}`;
  } catch (error) {
    const msg = error instanceof Error ? error.message : 'Error desconocido';
    return `Error al obtener medicamentos: ${msg}`;
  }
}

// Obtener todas las rutinas del paciente
export async function getPatientRoutines(userId: string, env: Env): Promise<string> {
  try {
    const data = await adaptaiRequest(
      `routines?userId=${userId}`,
      'GET',
      env
    );

    const routines = JSON.parse(data);
    if (!routines || routines.length === 0) {
      return 'El paciente no tiene rutinas registradas.';
    }

    const list = routines.map((r: any) => {
      const category = r.category || 'general';
      const steps = r.steps?.length || 0;
      return `- ${r.title} [${category}] (${steps} pasos)`;
    }).join('\n');

    return `Rutinas del paciente:\n${list}`;
  } catch (error) {
    const msg = error instanceof Error ? error.message : 'Error desconocido';
    return `Error al obtener rutinas: ${msg}`;
  }
}

// Obtener el horario de hoy del paciente
export async function getPatientSchedule(userId: string, env: Env): Promise<string> {
  try {
    const today = new Date().toISOString().split('T')[0];
    const data = await adaptaiRequest(
      `executions?userId=${userId}&date=${today}`,
      'GET',
      env
    );

    const executions = JSON.parse(data);
    if (!executions || executions.length === 0) {
      return 'No hay actividades programadas para hoy.';
    }

    const schedule = executions.map((e: any) => {
      const status = e.status === 'completed' ? 'completada'
        : e.status === 'in_progress' ? 'en progreso'
        : 'pendiente';
      const time = e.startedAt
        ? new Date(e.startedAt).toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' })
        : 'sin hora';
      return `- ${e.routine?.title || 'Actividad'} (${time}) — ${status}`;
    }).join('\n');

    return `Horario de hoy:\n${schedule}`;
  } catch (error) {
    const msg = error instanceof Error ? error.message : 'Error desconocido';
    return `Error al obtener horario: ${msg}`;
  }
}

// Obtener estado del robot
export async function getRobotStatus(robotId: string, env: Env): Promise<string> {
  try {
    const data = await adaptaiRequest(
      `robot/${robotId}/status`,
      'GET',
      env
    );

    const status = JSON.parse(data);
    const robot = status.robot;
    const t = status.latestTelemetry;

    let info = `Robot "${robot.name}" — Estado: ${robot.status}`;
    if (t) {
      info += `\nBatería: ${t.batteryPercent}%`;
      info += `\nDistancia al paciente: ${t.bleEstimatedDistance?.toFixed(1) || 'desconocida'} m`;
      info += `\nTarget BLE: ${t.bleTargetFound ? 'encontrado' : 'perdido'}`;
      info += `\nEstado de navegación: ${t.state}`;
    }

    return info;
  } catch (error) {
    const msg = error instanceof Error ? error.message : 'Error desconocido';
    return `Error al obtener estado del robot: ${msg}`;
  }
}

// Enviar comando al robot
export async function sendRobotCommand(
  robotId: string,
  command: string,
  env: Env
): Promise<string> {
  try {
    await adaptaiRequest(
      `robot/${robotId}/command`,
      'POST',
      env,
      { commandType: command }
    );

    const actions: Record<string, string> = {
      start: 'El robot comenzará a seguir al paciente.',
      stop: 'El robot se ha detenido.',
      pause: 'El robot está en pausa.',
      resume: 'El robot ha reanudado el seguimiento.',
      emergency_stop: 'PARADA DE EMERGENCIA activada.',
      reset: 'El robot se ha reiniciado.',
    };

    return actions[command] || `Comando "${command}" enviado al robot.`;
  } catch (error) {
    const msg = error instanceof Error ? error.message : 'Error desconocido';
    return `Error al enviar comando: ${msg}`;
  }
}
