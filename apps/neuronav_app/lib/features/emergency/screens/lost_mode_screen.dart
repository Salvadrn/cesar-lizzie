import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/profile_data.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_client.dart';

class LostModeScreen extends ConsumerWidget {
  const LostModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final profile = authState.currentProfile;

    final hasLostModeInfo = profile != null &&
        (profile.lostModeName?.isNotEmpty == true ||
            profile.lostModePhone?.isNotEmpty == true);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: hasLostModeInfo
          ? null // No app bar in display mode for maximum readability
          : AppBar(
              title: const Text('Modo Perdido'),
              centerTitle: true,
            ),
      body: SafeArea(
        child: hasLostModeInfo
            ? _LostModeDisplay(profile: profile)
            : _LostModeSetup(
                profile: profile,
                onSaved: () {
                  ref.read(authStateProvider.notifier).refreshProfile();
                },
              ),
      ),
    );
  }
}

// =============================================================================
// Lost Mode Display -- high-contrast, for strangers to read
// =============================================================================

class _LostModeDisplay extends StatelessWidget {
  final ProfileData profile;

  const _LostModeDisplay({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Back button row
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                iconSize: 28,
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade800,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.info_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'INFORMACION DE CONTACTO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Esta persona puede necesitar ayuda.\nPor favor contacte al numero abajo.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Name
                  if (profile.lostModeName?.isNotEmpty == true) ...[
                    _InfoRow(
                      icon: Icons.person_rounded,
                      label: 'NOMBRE',
                      value: profile.lostModeName!,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Address
                  if (profile.lostModeAddress?.isNotEmpty == true) ...[
                    _InfoRow(
                      icon: Icons.home_rounded,
                      label: 'DIRECCION',
                      value: profile.lostModeAddress!,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Phone
                  if (profile.lostModePhone?.isNotEmpty == true) ...[
                    _InfoRow(
                      icon: Icons.phone_rounded,
                      label: 'TELEFONO DE EMERGENCIA',
                      value: profile.lostModePhone!,
                    ),
                    const SizedBox(height: 32),

                    // Large call button
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final uri =
                              Uri.parse('tel:${profile.lostModePhone}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        icon: const Icon(Icons.phone_rounded, size: 28),
                        label: Text(
                          'Llamar: ${profile.lostModePhone}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Lost Mode Setup -- form to configure lost mode information
// =============================================================================

class _LostModeSetup extends StatefulWidget {
  final ProfileData? profile;
  final VoidCallback onSaved;

  const _LostModeSetup({
    required this.profile,
    required this.onSaved,
  });

  @override
  State<_LostModeSetup> createState() => _LostModeSetupState();
}

class _LostModeSetupState extends State<_LostModeSetup> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.profile?.lostModeName ?? '',
    );
    _addressController = TextEditingController(
      text: widget.profile?.lostModeAddress ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.profile?.lostModePhone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Configurar Modo Perdido',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Esta informacion se mostrara en pantalla si necesitas ayuda '
              'y alguien encuentra tu dispositivo.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tu nombre',
                prefixIcon: Icon(Icons.person_rounded),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 18),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Direccion de casa',
                prefixIcon: Icon(Icons.home_rounded),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 18),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefono de emergencia',
                prefixIcon: Icon(Icons.phone_rounded),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 18),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ApiClient.updateProfile(ProfileUpdate(
        lostModeName: _nameController.text.trim(),
        lostModeAddress: _addressController.text.trim(),
        lostModePhone: _phoneController.text.trim(),
      ));

      widget.onSaved();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informacion de Modo Perdido guardada'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
