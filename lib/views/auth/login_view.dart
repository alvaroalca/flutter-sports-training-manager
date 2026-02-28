/// Pantalla de inicio de sesión.
///
/// Presenta un formulario con email y contraseña. Valida los campos antes
/// de enviar la petición y muestra errores tanto de validación (inline)
/// como de autenticación (SnackBar). Tras un login exitoso, navega a la
/// pantalla principal unificada [AppRoutes.home].
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/auth_controller.dart';
import 'package:tfg/core/theme/app_colors.dart';
import 'package:tfg/core/constants/app_routes.dart';
import 'package:tfg/core/l10n/app_strings.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  /// Clave global del formulario para acceder a la validación.
  final _formKey = GlobalKey<FormState>();

  /// Controladores de texto para los campos del formulario.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Controla si la contraseña se muestra en texto plano o enmascarada.
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Liberar los controladores al destruir el widget para evitar fugas de memoria.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valida el formulario y ejecuta el inicio de sesión.
  Future<void> _submit() async {
    // Detener si algún campo no supera la validación
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<AuthController>();

    final success = await controller.iniciarSesion(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Navegar a la pantalla principal unificada
      context.go(AppRoutes.home);
    } else {
      // Mostrar el error de autenticación en un SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? AppStrings.errorGeneric),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthController>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Logo / Título ──────────────────────────
                const Icon(
                  Icons.gps_fixed,
                  size: 72,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestión de entrenamiento de tiro olímpico',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 40),

                // ── Formulario ─────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Campo email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: AppStrings.email,
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.fieldRequired;
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return AppStrings.emailInvalid;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo contraseña
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: AppStrings.password,
                          prefixIcon: const Icon(Icons.lock_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.fieldRequired;
                          }
                          if (value.length < 6) {
                            return AppStrings.passwordShort;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Botón de inicio de sesión
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(AppStrings.login),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Enlace a registro ──────────────────────
                TextButton(
                  onPressed: () => context.go(AppRoutes.register),
                  child: const Text(
                    AppStrings.noAccount,
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
