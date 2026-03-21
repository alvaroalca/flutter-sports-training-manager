/// Pantalla para crear un nuevo entrenamiento o plantilla.
///
/// Solo accesible para el rol [Rol.entrenador]. Permite introducir el nombre,
/// descripción, fecha programada y los ejercicios que componen la sesión.
/// Los ejercicios se crean inline y se añaden a la lista antes de guardar.
///
/// Al guardar llama a [EntrenamientoController.crearEntrenamiento] y navega
/// de vuelta al listado si la operación tiene éxito.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/auth_controller.dart';
import 'package:tfg/controllers/entrenamiento_controller.dart';
import 'package:tfg/core/theme/app_colors.dart';
import 'package:tfg/core/l10n/app_strings.dart';
import 'package:tfg/models/ejercicio.dart';
import 'package:tfg/services/firestore_service.dart';
import 'package:tfg/shared/widgets/app_scaffold.dart';

class CrearEntrenamientoView extends StatefulWidget {
  const CrearEntrenamientoView({super.key});

  @override
  State<CrearEntrenamientoView> createState() => _CrearEntrenamientoViewState();
}

class _CrearEntrenamientoViewState extends State<CrearEntrenamientoView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();

  DateTime? _fechaProgramada;

  /// Lista de ejercicios añadidos a esta sesión antes de guardar.
  final List<Ejercicio> _ejercicios = [];

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ejercicios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos un ejercicio al entrenamiento.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final entrenadorId = context.read<AuthController>().usuario!.uid;
    final firestoreService = FirestoreService();

    // Persistir cada ejercicio en Firestore y recoger sus IDs
    final List<String> ejerciciosIds = [];
    for (final ejercicio in _ejercicios) {
      final id = await firestoreService.crearEjercicio(ejercicio);
      ejerciciosIds.add(id);
    }

    if (!mounted) return;

    final id = await context.read<EntrenamientoController>().crearEntrenamiento(
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim(),
          entrenadorId: entrenadorId,
          ejerciciosIds: ejerciciosIds,
          fechaProgramada: _fechaProgramada,
        );

    if (!mounted) return;

    if (id != null) {
      context.pop();
    } else {
      final error = context.read<EntrenamientoController>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? AppStrings.errorGeneric),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Abre el diálogo para añadir un nuevo ejercicio a la lista.
  Future<void> _abrirDialogoEjercicio() async {
    final ejercicio = await showDialog<Ejercicio>(
      context: context,
      builder: (_) => const _DialogoEjercicio(),
    );
    if (ejercicio != null) {
      setState(() => _ejercicios.add(ejercicio));
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha != null) setState(() => _fechaProgramada = fecha);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<EntrenamientoController>().isLoading;

    return AppScaffold(
      title: 'Nuevo entrenamiento',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Datos generales ────────────────────────
            TextFormField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre del entrenamiento',
                prefixIcon: Icon(Icons.fitness_center),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppStrings.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción / objetivos',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppStrings.fieldRequired : null,
            ),
            const SizedBox(height: 16),

            // ── Fecha programada ───────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: AppColors.primary),
              title: Text(
                _fechaProgramada == null
                    ? 'Fecha programada (opcional)'
                    : 'Fecha: ${_fechaProgramada!.day}/${_fechaProgramada!.month}/${_fechaProgramada!.year}',
                style: TextStyle(
                  color: _fechaProgramada == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
              trailing: _fechaProgramada != null
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _fechaProgramada = null),
                    )
                  : null,
              onTap: _seleccionarFecha,
            ),
            const Divider(),
            const SizedBox(height: 8),

            // ── Lista de ejercicios ────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ejercicios (${_ejercicios.length})',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: _abrirDialogoEjercicio,
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text('Añadir',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Lista de ejercicios añadidos
            if (_ejercicios.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Sin ejercicios aún. Pulsa "Añadir" para crear uno.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ejercicios.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _ejercicios.removeAt(oldIndex);
                    _ejercicios.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final e = _ejercicios[index];
                  return ListTile(
                    key: ValueKey(index),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text('${index + 1}',
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(e.nombre),
                    subtitle: Text(
                      '${e.numDisparos} disparos · ${e.repeticiones} series · '
                      '${e.tiempoPreparacion}s prep / ${e.tiempoApuntado}s apunt',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () =>
                          setState(() => _ejercicios.removeAt(index)),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),

            // ── Botón guardar ──────────────────────────
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(AppStrings.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diálogo para añadir un ejercicio
// ─────────────────────────────────────────────────────────────────────────────

/// Diálogo modal para definir los parámetros de un nuevo ejercicio.
///
/// Devuelve un [Ejercicio] con un ID vacío (se asignará al persistirlo en Firestore)
/// o null si el usuario cancela.
class _DialogoEjercicio extends StatefulWidget {
  const _DialogoEjercicio();

  @override
  State<_DialogoEjercicio> createState() => _DialogoEjercicioState();
}

class _DialogoEjercicioState extends State<_DialogoEjercicio> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _prepCtrl = TextEditingController(text: '10');
  final _apuntCtrl = TextEditingController(text: '8');
  final _disparosCtrl = TextEditingController(text: '5');
  final _repsCtrl = TextEditingController(text: '3');
  final _notasCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _prepCtrl.dispose();
    _apuntCtrl.dispose();
    _disparosCtrl.dispose();
    _repsCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  void _aceptar() {
    if (!_formKey.currentState!.validate()) return;
    final ejercicio = Ejercicio(
      id: '',
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
      tiempoPreparacion: int.parse(_prepCtrl.text),
      tiempoApuntado: int.parse(_apuntCtrl.text),
      numDisparos: int.parse(_disparosCtrl.text),
      repeticiones: int.parse(_repsCtrl.text),
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    );
    Navigator.of(context).pop(ejercicio);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo ejercicio'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Campo(controller: _nombreCtrl, label: 'Nombre del ejercicio'),
              _Campo(
                  controller: _descCtrl,
                  label: 'Descripción',
                  maxLines: 2),
              Row(children: [
                Expanded(
                    child: _CampoNumero(
                        controller: _prepCtrl,
                        label: 'Preparación (s)')),
                const SizedBox(width: 8),
                Expanded(
                    child: _CampoNumero(
                        controller: _apuntCtrl, label: 'Apuntado (s)')),
              ]),
              Row(children: [
                Expanded(
                    child: _CampoNumero(
                        controller: _disparosCtrl, label: 'Disparos')),
                const SizedBox(width: 8),
                Expanded(
                    child: _CampoNumero(
                        controller: _repsCtrl, label: 'Series')),
              ]),
              _Campo(
                  controller: _notasCtrl,
                  label: 'Notas (opcional)',
                  required: false),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _aceptar,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          child: const Text(AppStrings.accept),
        ),
      ],
    );
  }
}

/// Campo de texto genérico para el diálogo de ejercicio.
class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final bool required;

  const _Campo({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                ? AppStrings.fieldRequired
                : null
            : null,
      ),
    );
  }
}

/// Campo numérico para el diálogo de ejercicio con validación de entero positivo.
class _CampoNumero extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _CampoNumero(
      {required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return AppStrings.fieldRequired;
          final n = int.tryParse(v);
          if (n == null || n <= 0) return 'Número > 0';
          return null;
        },
      ),
    );
  }
}
