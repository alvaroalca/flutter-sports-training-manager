/// Pantalla para que el entrenador cree un nuevo grupo de entrenamiento.
///
/// Recoge el nombre, la descripción y una foto de portada opcional.
/// Al guardar, el controlador crea el documento en Firestore, le asigna un
/// código único (#000001) y, si se eligió foto, la sube a Firebase Storage.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/auth_controller.dart';
import 'package:tfg/controllers/grupos_controller.dart';
import 'package:tfg/core/theme/app_colors.dart';
import 'package:tfg/core/constants/app_routes.dart';
import 'package:tfg/shared/widgets/app_scaffold.dart';

class CrearGrupoView extends StatefulWidget {
  const CrearGrupoView({super.key});

  @override
  State<CrearGrupoView> createState() => _CrearGrupoViewState();
}

class _CrearGrupoViewState extends State<CrearGrupoView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  /// Bytes de la imagen seleccionada (null si no se ha elegido ninguna).
  Uint8List? _fotoBytes;
  String _fotoExtension = 'jpg';

  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  /// Abre el selector de imágenes del sistema y guarda los bytes localmente.
  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    setState(() {
      _fotoBytes = bytes;
      _fotoExtension = ext.isEmpty ? 'jpg' : ext;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final entrenadorId = context.read<AuthController>().usuario!.uid;
    final ctrl = context.read<GruposController>();

    final grupoId = await ctrl.crearGrupo(
      nombre: _nombreCtrl.text,
      descripcion: _descCtrl.text,
      entrenadorId: entrenadorId,
    );

    if (!mounted) return;

    if (grupoId == null) {
      setState(() => _guardando = false);
      final error = ctrl.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al crear el grupo.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Subir foto si el entrenador eligió una
    if (_fotoBytes != null) {
      await ctrl.subirFotoGrupo(
        grupoId: grupoId,
        bytes: _fotoBytes!,
        extension: _fotoExtension,
      );
    }

    if (!mounted) return;
    setState(() => _guardando = false);

    // pushReplacement: sustituye esta pantalla por el detalle, manteniendo
    // la lista de grupos en el stack para que el back button funcione.
    context.pushReplacement(
      AppRoutes.detalleGrupo.replaceFirst(':id', grupoId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nuevo grupo',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Selector de foto de portada ─────────────────
              _SelectorFoto(
                bytes: _fotoBytes,
                onTap: _seleccionarFoto,
              ),
              const SizedBox(height: 24),

              // ── Nombre ──────────────────────────────────────
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del grupo *',
                  hintText: 'Ej. Pistola 10m Juniors',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Introduce un nombre' : null,
              ),
              const SizedBox(height: 16),

              // ── Descripción ─────────────────────────────────
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Ej. Grupo de preparación para campeonato autonómico',
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // ── Botón guardar ────────────────────────────────
              ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: const Text('Crear grupo', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget selector de foto
// ─────────────────────────────────────────────────────────────────────────────

/// Área táctil que muestra la foto elegida o un placeholder con icono de cámara.
class _SelectorFoto extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback onTap;

  const _SelectorFoto({required this.bytes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          image: bytes != null
              ? DecorationImage(
                  image: MemoryImage(bytes!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: bytes == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 40, color: AppColors.primary),
                  SizedBox(height: 8),
                  Text(
                    'Añadir foto de portada (opcional)',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ],
              )
            : const Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
              ),
      ),
    );
  }
}
