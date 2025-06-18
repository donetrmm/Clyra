import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';

/// Widget que detecta automáticamente las interacciones del usuario
/// y actualiza el timer de actividad de la sesión
class ActivityDetector extends StatelessWidget {
  final Widget child;

  const ActivityDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _updateActivity(context),
      onPointerMove: (_) => _updateActivity(context),
      onPointerUp: (_) => _updateActivity(context),
      child: GestureDetector(
        onTap: () => _updateActivity(context),
        onScaleStart: (_) => _updateActivity(context),
        behavior: HitTestBehavior.translucent,
        child: child,
      ),
    );
  }

  void _updateActivity(BuildContext context) {
    // Verificar que el contexto esté montado antes de acceder al provider
    if (!context.mounted) return;

    try {
      // Actualizar actividad en el AuthViewModel
      final authViewModel = context.read<AuthViewModel>();
      authViewModel.updateActivity();
    } catch (e) {
      // Silenciar errores de provider si el widget ya no está montado
      debugPrint('ActivityDetector: Error updating activity: $e');
    }
  }
}

/// Mixin para widgets que necesitan actualizar automáticamente la actividad
mixin ActivityAware<T extends StatefulWidget> on State<T> {
  void updateActivity() {
    if (!mounted) return;

    try {
      final authViewModel = context.read<AuthViewModel>();
      authViewModel.updateActivity();
    } catch (e) {
      debugPrint('ActivityAware: Error updating activity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ActivityDetector(child: buildWithActivityDetection(context));
  }

  /// Método que deben implementar los widgets que usen este mixin
  Widget buildWithActivityDetection(BuildContext context);
}
