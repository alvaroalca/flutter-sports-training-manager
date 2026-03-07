/// Pantalla de perfil del usuario autenticado.
///
/// Muestra la foto de perfil, el código de usuario y los datos personales
/// (nombre, apellidos, email). Permite cambiar la foto y editar nombre/apellidos.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/auth_controller.dart';
import 'package:tfg/core/theme/app_colors.dart';
import 'package:tfg/core/theme/app_text_styles.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  bool _editando = false;
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidosCtrl;

  @override
  void initState() {
    super.initState();
    final usuario = context.read<AuthController>().usuario;
    _nombreCtrl = TextEditingController(text: usuario?.nombre ?? '');
    _apellidosCtrl = TextEditingController(text: usuario?.apellidos ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    super.dispose();
  }

  /// Abre la galería del dispositivo, comprime la imagen seleccionada
  /// y la sube a Firebase Storage actualizando el perfil del usuario.
  Future<void> _cambiarFoto() async {
    final ctrl = context.read<AuthController>();
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    if (!mounted) return;
    final url = await ctrl.subirFotoPerfil(bytes, ext.isEmpty ? 'jpg' : ext);
    if (url == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la foto.')),
      );
    }
  }

  /// Valida los campos de nombre y apellidos y, si son correctos,
  /// actualiza el perfil en Firestore y sale del modo edición.
  Future<void> _guardarCambios() async {
    final ctrl = context.read<AuthController>();
    final nombre = _nombreCtrl.text.trim();
    final apellidos = _apellidosCtrl.text.trim();
    if (nombre.isEmpty || apellidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre y los apellidos no pueden estar vacíos.')),
      );
      return;
    }
    final ok = await ctrl.actualizarPerfil(nombre: nombre, apellidos: apellidos);
    if (!mounted) return;
    if (ok) {
      setState(() => _editando = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron guardar los cambios.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthController>().usuario;
    final isLoading = context.watch<AuthController>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Mi perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_editando)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar perfil',
              onPressed: () => setState(() => _editando = true),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancelar',
              onPressed: () {
                final u = context.read<AuthController>().usuario;
                _nombreCtrl.text = u?.nombre ?? '';
                _apellidosCtrl.text = u?.apellidos ?? '';
                setState(() => _editando = false);
              },
            ),
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Guardar',
              onPressed: isLoading ? null : _guardarCambios,
            ),
          ],
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // ── Avatar ──────────────────────────────────────────────
                  GestureDetector(
                    onTap: _cambiarFoto,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          backgroundImage: usuario?.fotoPerfil != null
                              ? NetworkImage(usuario!.fotoPerfil!)
                              : null,
                          child: usuario?.fotoPerfil == null
                              ? Text(
                                  usuario?.nombre.isNotEmpty == true
                                      ? usuario!.nombre[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toca el avatar para cambiar la foto',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  // ── Código de usuario ───────────────────────────────────
                  _InfoTile(
                    icon: Icons.tag,
                    label: 'Código de usuario',
                    value: usuario?.codigoUsuario ?? '—',
                  ),
                  const SizedBox(height: 12),

                  // ── Email (no editable) ─────────────────────────────────
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Correo electrónico',
                    value: usuario?.email ?? '—',
                  ),
                  const SizedBox(height: 12),

                  // ── Nombre ──────────────────────────────────────────────
                  _editando
                      ? _CampoEdicion(
                          label: 'Nombre',
                          controller: _nombreCtrl,
                          icon: Icons.person_outline,
                        )
                      : _InfoTile(
                          icon: Icons.person_outline,
                          label: 'Nombre',
                          value: usuario?.nombre ?? '—',
                        ),
                  const SizedBox(height: 12),

                  // ── Apellidos ───────────────────────────────────────────
                  _editando
                      ? _CampoEdicion(
                          label: 'Apellidos',
                          controller: _apellidosCtrl,
                          icon: Icons.badge_outlined,
                        )
                      : _InfoTile(
                          icon: Icons.badge_outlined,
                          label: 'Apellidos',
                          value: usuario?.apellidos ?? '—',
                        ),

                  if (_editando) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading ? null : _guardarCambios,
                        child: const Text('Guardar cambios',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

/// Tarjeta de solo lectura que muestra un campo de perfil con icono,
/// etiqueta y valor. Se usa para email, código de usuario, nombre y apellidos
/// cuando [_editando] es false.
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de texto editable que reemplaza a [_InfoTile] cuando el usuario
/// activa el modo edición. Se usa para nombre y apellidos.
class _CampoEdicion extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;

  const _CampoEdicion({
    required this.label,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
