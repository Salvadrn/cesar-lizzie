import 'package:flutter/material.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Creditos')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          const SizedBox(height: 16),

          // -- App icon & name --
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'NeuroNav',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Asistente de Vida Diaria Adaptativo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // -- Dedicatoria --
          _buildSection(
            context: context,
            icon: Icons.favorite_rounded,
            iconColor: Colors.red,
            title: 'Dedicado a Diego',
            child: Text(
              'Esta aplicacion esta dedicada a Diego y a todas las personas que, '
              'como el, merecen las herramientas para vivir con independencia y dignidad.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // -- Desarrollado por --
          _buildSection(
            context: context,
            icon: Icons.code_rounded,
            iconColor: colorScheme.primary,
            title: 'Desarrollado por',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Equipo NeuroNav',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Creado con el proposito de mejorar la calidad de vida de adultos con discapacidades cognitivas.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // -- Tecnologias --
          _buildSection(
            context: context,
            icon: Icons.build_rounded,
            iconColor: const Color(0xFFFF9500),
            title: 'Tecnologias',
            child: Column(
              children: [
                _technologyRow(
                  context,
                  icon: Icons.flutter_dash,
                  name: 'Flutter',
                  description: 'Framework de interfaz multiplataforma',
                ),
                const SizedBox(height: 12),
                _technologyRow(
                  context,
                  icon: Icons.cloud_rounded,
                  name: 'Supabase',
                  description: 'Backend, autenticacion y base de datos',
                ),
                const SizedBox(height: 12),
                _technologyRow(
                  context,
                  icon: Icons.apple,
                  name: 'Apple Sign In',
                  description: 'Autenticacion segura con Apple',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // -- Codigo Abierto --
          _buildSection(
            context: context,
            icon: Icons.public_rounded,
            iconColor: const Color(0xFF34C759),
            title: 'Codigo Abierto',
            child: Text(
              'NeuroNav es un asistente adaptativo de vida diaria disenado para adultos con discapacidades cognitivas. '
              'Proporciona rutinas paso a paso, recordatorios de medicamentos, '
              'deteccion de emergencias y herramientas de supervision familiar.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
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
    required String title,
    required Widget child,
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
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _technologyRow(
    BuildContext context, {
    required IconData icon,
    required String name,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: colorScheme.onSurface),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
