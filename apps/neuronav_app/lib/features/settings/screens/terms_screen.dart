import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Terminos y Condiciones')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          const SizedBox(height: 8),

          // -- Introduccion --
          Text(
            'Al utilizar NeuroNav, aceptas los siguientes terminos y condiciones. '
            'Por favor, leelos cuidadosamente.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 20),

          // 1. Naturaleza de la aplicacion
          _buildSection(
            context: context,
            icon: Icons.info_outline_rounded,
            iconColor: colorScheme.primary,
            number: '1',
            title: 'Naturaleza de la Aplicacion',
            body: 'NeuroNav es una herramienta de apoyo disenada para asistir en la vida diaria. '
                'NO es un dispositivo medico, ni sustituye el cuidado profesional de salud, '
                'terapia ocupacional, ni cualquier otro servicio de atencion medica. '
                'Las funciones de la aplicacion son orientativas y complementarias.',
          ),

          const SizedBox(height: 16),

          // 2. Medicamentos y recordatorios
          _buildSection(
            context: context,
            icon: Icons.medication_rounded,
            iconColor: const Color(0xFFFF3B30),
            number: '2',
            title: 'Medicamentos y Recordatorios',
            body: 'NeuroNav puede enviar recordatorios de medicamentos, pero NO garantiza la '
                'adherencia a los mismos. Si el usuario no toma sus medicamentos a pesar de '
                'los recordatorios, NeuroNav y sus desarrolladores NO son responsables de las '
                'consecuencias derivadas. La responsabilidad del cumplimiento del tratamiento '
                'recae exclusivamente en el usuario y/o su cuidador.',
          ),

          const SizedBox(height: 16),

          // 3. Responsabilidad del cuidador
          _buildSection(
            context: context,
            icon: Icons.people_rounded,
            iconColor: const Color(0xFF5856D6),
            number: '3',
            title: 'Responsabilidad del Cuidador',
            body: 'NeuroNav esta disenada para adultos con discapacidades cognitivas. '
                'El usuario y/o su tutor legal o cuidador asumen la responsabilidad total '
                'del cuidado del usuario. La aplicacion es una herramienta de apoyo y no '
                'reemplaza la supervision humana ni el juicio profesional.',
          ),

          const SizedBox(height: 16),

          // 4. Almacenamiento de datos
          _buildSection(
            context: context,
            icon: Icons.storage_rounded,
            iconColor: const Color(0xFF34C759),
            number: '4',
            title: 'Almacenamiento de Datos',
            body: 'Los datos del usuario se almacenan de forma segura utilizando servicios '
                'de infraestructura confiables. Al utilizar la aplicacion, el usuario acepta '
                'la politica de manejo de datos, incluyendo el almacenamiento de informacion '
                'personal, datos de rutinas, medicamentos e informacion de contactos de emergencia.',
          ),

          const SizedBox(height: 16),

          // 5. Notificaciones y alertas
          _buildSection(
            context: context,
            icon: Icons.notifications_active_rounded,
            iconColor: const Color(0xFFFF9500),
            number: '5',
            title: 'Notificaciones y Alertas',
            body: 'Las notificaciones y recordatorios se envian con el mejor esfuerzo posible. '
                'Sin embargo, pueden fallar o retrasarse debido a restricciones del sistema operativo, '
                'optimizacion de bateria, falta de conexion a internet, actualizaciones del dispositivo '
                'u otros factores fuera del control de NeuroNav. No se garantiza la entrega puntual '
                'de ninguna notificacion.',
          ),

          const SizedBox(height: 16),

          // 6. Deteccion de emergencias y ubicacion
          _buildSection(
            context: context,
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFFFF2D55),
            number: '6',
            title: 'Deteccion de Emergencias y Ubicacion',
            body: 'La aplicacion puede utilizar funciones de deteccion de caidas, deteccion de '
                'inactividad y servicios de ubicacion con el fin de mejorar la seguridad del usuario. '
                'Al utilizar estas funciones, el usuario consiente al uso de estos servicios. '
                'Estas funciones son complementarias y no sustituyen un sistema de emergencias profesional.',
          ),

          const SizedBox(height: 16),

          // 7. Limitacion de responsabilidad
          _buildSection(
            context: context,
            icon: Icons.gavel_rounded,
            iconColor: colorScheme.onSurface.withValues(alpha: 0.7),
            number: '7',
            title: 'Limitacion de Responsabilidad',
            body: 'NeuroNav y sus desarrolladores no seran responsables de ningun dano, lesion, '
                'consecuencia medica o perjuicio de cualquier tipo que surja del uso o la '
                'imposibilidad de uso de la aplicacion. Esto incluye, pero no se limita a, '
                'fallas en recordatorios, perdida de datos, o funcionamiento incorrecto de '
                'las funciones de seguridad.',
          ),

          const SizedBox(height: 16),

          // 8. Sin garantias
          _buildSection(
            context: context,
            icon: Icons.shield_rounded,
            iconColor: const Color(0xFF007AFF),
            number: '8',
            title: 'Sin Garantias',
            body: 'La aplicacion se proporciona "tal cual" (as-is) sin garantias de ningun tipo, '
                'ya sean expresas o implicitas. No se garantiza que la aplicacion funcione sin '
                'interrupciones, errores o defectos. El uso de la aplicacion es bajo el propio '
                'riesgo del usuario.',
          ),

          const SizedBox(height: 16),

          // 9. Edad minima
          _buildSection(
            context: context,
            icon: Icons.person_rounded,
            iconColor: const Color(0xFF5AC8FA),
            number: '9',
            title: 'Edad Minima y Tutores Legales',
            body: 'El usuario debe tener 18 anos o mas para utilizar la aplicacion. '
                'En el caso de usuarios menores de 18 anos o personas que requieran un tutor legal, '
                'este debe aceptar los presentes terminos y condiciones en nombre del usuario '
                'y supervisar su uso de la aplicacion.',
          ),

          const SizedBox(height: 16),

          // 10. Actualizaciones de los terminos
          _buildSection(
            context: context,
            icon: Icons.update_rounded,
            iconColor: const Color(0xFFAF52DE),
            number: '10',
            title: 'Actualizaciones de los Terminos',
            body: 'Estos terminos y condiciones pueden ser actualizados periodicamente. '
                'El uso continuado de la aplicacion despues de cualquier modificacion '
                'constituye la aceptacion de los nuevos terminos. Se recomienda revisar '
                'esta seccion regularmente.',
          ),

          const SizedBox(height: 32),

          // -- Footer --
          Center(
            child: Column(
              children: [
                Text(
                  'NeuroNav v1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ultima actualizacion: Febrero 2026',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String number,
    required String title,
    required String body,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$number. $title',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
