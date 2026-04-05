// ============================================================
// Integracion con Notion API v2022-06-28
// Usa Internal Integration Token para autenticacion
// ============================================================

import type { Env } from './types';

const NOTION_API_URL = 'https://api.notion.com/v1';
const NOTION_VERSION = '2022-06-28';

// Headers comunes para las peticiones a Notion
function getHeaders(env: Env): Record<string, string> {
  return {
    'Authorization': `Bearer ${env.NOTION_API_KEY}`,
    'Notion-Version': NOTION_VERSION,
    'Content-Type': 'application/json'
  };
}

// Busca paginas y documentos en Notion
export async function searchNotion(query: string, env: Env): Promise<string> {
  const response = await fetch(`${NOTION_API_URL}/search`, {
    method: 'POST',
    headers: getHeaders(env),
    body: JSON.stringify({
      query,
      sort: {
        direction: 'descending',
        timestamp: 'last_edited_time'
      },
      page_size: 10
    })
  });

  if (!response.ok) {
    throw new Error(`Error al buscar en Notion: ${response.status}`);
  }

  const data = await response.json() as {
    results: Array<{
      object: string;
      id: string;
      properties?: Record<string, {
        title?: Array<{ plain_text: string }>;
        [key: string]: unknown;
      }>;
      url?: string;
      last_edited_time?: string;
    }>;
  };

  const results = data.results || [];

  if (results.length === 0) {
    return `No se encontraron resultados para "${query}" en Notion.`;
  }

  const formatted = results.slice(0, 5).map((result, i) => {
    let title = 'Sin título';

    // Extraer titulo de las propiedades
    if (result.properties) {
      for (const prop of Object.values(result.properties)) {
        if (prop.title && prop.title.length > 0) {
          title = prop.title.map(t => t.plain_text).join('');
          break;
        }
      }
    }

    const type = result.object === 'database' ? 'Base de datos' : 'Página';
    const edited = result.last_edited_time
      ? new Date(result.last_edited_time).toLocaleDateString('es-MX', { dateStyle: 'medium' })
      : '';

    return `${i + 1}. [${type}] ${title}${edited ? ` (editado: ${edited})` : ''}`;
  });

  return `Resultados en Notion para "${query}":\n${formatted.join('\n')}`;
}

// Crea una nueva pagina en Notion
export async function createPage(
  title: string,
  content: string,
  parentId: string | undefined,
  env: Env
): Promise<string> {
  // Convertir contenido markdown a bloques de Notion
  const children = markdownToNotionBlocks(content);

  // Construir el body de la solicitud
  const body: Record<string, unknown> = {
    properties: {
      title: {
        title: [{ text: { content: title } }]
      }
    },
    children
  };

  // Si se proporciona un ID de padre, usarlo; si no, crear en workspace
  if (parentId) {
    body.parent = { page_id: parentId };
  } else {
    // Crear como pagina de nivel superior en el workspace
    body.parent = { type: 'workspace', workspace: true };
  }

  const response = await fetch(`${NOTION_API_URL}/pages`, {
    method: 'POST',
    headers: getHeaders(env),
    body: JSON.stringify(body)
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Error al crear página en Notion: ${error}`);
  }

  const created = await response.json() as { id: string; url: string };

  return `Página "${title}" creada exitosamente en Notion.`;
}

// Convierte texto markdown basico a bloques de Notion
function markdownToNotionBlocks(markdown: string): Array<Record<string, unknown>> {
  const lines = markdown.split('\n');
  const blocks: Array<Record<string, unknown>> = [];

  for (const line of lines) {
    const trimmed = line.trim();

    // Lineas vacias: agregar bloque vacio
    if (trimmed === '') {
      continue;
    }

    // Encabezado nivel 1
    if (trimmed.startsWith('# ')) {
      blocks.push({
        object: 'block',
        type: 'heading_1',
        heading_1: {
          rich_text: [{ type: 'text', text: { content: trimmed.substring(2) } }]
        }
      });
      continue;
    }

    // Encabezado nivel 2
    if (trimmed.startsWith('## ')) {
      blocks.push({
        object: 'block',
        type: 'heading_2',
        heading_2: {
          rich_text: [{ type: 'text', text: { content: trimmed.substring(3) } }]
        }
      });
      continue;
    }

    // Encabezado nivel 3
    if (trimmed.startsWith('### ')) {
      blocks.push({
        object: 'block',
        type: 'heading_3',
        heading_3: {
          rich_text: [{ type: 'text', text: { content: trimmed.substring(4) } }]
        }
      });
      continue;
    }

    // Lista con viñetas
    if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
      blocks.push({
        object: 'block',
        type: 'bulleted_list_item',
        bulleted_list_item: {
          rich_text: [{ type: 'text', text: { content: trimmed.substring(2) } }]
        }
      });
      continue;
    }

    // Lista numerada
    const numberedMatch = trimmed.match(/^\d+\.\s(.+)/);
    if (numberedMatch) {
      blocks.push({
        object: 'block',
        type: 'numbered_list_item',
        numbered_list_item: {
          rich_text: [{ type: 'text', text: { content: numberedMatch[1] } }]
        }
      });
      continue;
    }

    // Texto de checkbox / tarea
    if (trimmed.startsWith('- [ ] ') || trimmed.startsWith('- [x] ')) {
      const checked = trimmed.startsWith('- [x] ');
      const text = trimmed.substring(6);
      blocks.push({
        object: 'block',
        type: 'to_do',
        to_do: {
          rich_text: [{ type: 'text', text: { content: text } }],
          checked
        }
      });
      continue;
    }

    // Parrafo por defecto
    blocks.push({
      object: 'block',
      type: 'paragraph',
      paragraph: {
        rich_text: [{ type: 'text', text: { content: trimmed } }]
      }
    });
  }

  return blocks;
}
