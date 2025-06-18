import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';

/// Widget que muestra un indicador del estado de la sesión
/// y tiempo restante antes del cierre automático
class SessionIndicator extends StatefulWidget {
  final bool showTimeRemaining;
  final bool showAsFloating;

  const SessionIndicator({
    super.key,
    this.showTimeRemaining = true,
    this.showAsFloating = false,
  });

  @override
  State<SessionIndicator> createState() => _SessionIndicatorState();
}

class _SessionIndicatorState extends State<SessionIndicator> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _startUpdateTimer();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Forzar actualización cada segundo
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        if (!authViewModel.isLoggedIn || !authViewModel.isSessionActive) {
          return const SizedBox.shrink();
        }

        final remainingSeconds = authViewModel.sessionRemainingSeconds;

        // Mostrar advertencia cuando quedan menos de 60 segundos
        final isWarning = remainingSeconds <= 60 && remainingSeconds > 0;
        final isCritical = remainingSeconds <= 30 && remainingSeconds > 0;

        if (!widget.showTimeRemaining && remainingSeconds > 60) {
          return const SizedBox.shrink();
        }

        final minutes = remainingSeconds ~/ 60;
        final seconds = remainingSeconds % 60;

        Color indicatorColor = AppTheme.accentTeal;
        IconData indicatorIcon = Icons.check_circle;

        if (isCritical) {
          indicatorColor = AppTheme.errorColor;
          indicatorIcon = Icons.warning;
        } else if (isWarning) {
          indicatorColor = AppTheme.warningColor;
          indicatorIcon = Icons.access_time;
        }

        Widget content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: indicatorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: indicatorColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(indicatorIcon, size: 16, color: indicatorColor),
              const SizedBox(width: 6),
              Text(
                widget.showTimeRemaining
                    ? '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
                    : 'Sesión activa',
                style: TextStyle(
                  color: indicatorColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

        if (widget.showAsFloating) {
          return Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 16,
            child: content,
          );
        }

        return content;
      },
    );
  }
}

/// Widget que muestra una barra de progreso de la sesión
class SessionProgressBar extends StatefulWidget {
  const SessionProgressBar({super.key});

  @override
  State<SessionProgressBar> createState() => _SessionProgressBarState();
}

class _SessionProgressBarState extends State<SessionProgressBar> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _startUpdateTimer();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Forzar actualización cada segundo
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        if (!authViewModel.isLoggedIn || !authViewModel.isSessionActive) {
          return const SizedBox.shrink();
        }

        final remainingSeconds = authViewModel.sessionRemainingSeconds;
        final timeoutMinutes = authViewModel.sessionTimeoutMinutes;
        final totalSeconds = timeoutMinutes * 60;

        if (totalSeconds <= 0) {
          return const SizedBox.shrink();
        }

        final progress =
            remainingSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;

        Color progressColor = AppTheme.accentTeal;
        if (progress <= 0.1) {
          progressColor = AppTheme.errorColor;
        } else if (progress <= 0.3) {
          progressColor = AppTheme.warningColor;
        }

        return Container(
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dialog de advertencia cuando la sesión está por expirar
class SessionExpiryWarningDialog extends StatelessWidget {
  final int remainingSeconds;
  final VoidCallback onExtendSession;
  final VoidCallback onLogoutNow;

  const SessionExpiryWarningDialog({
    super.key,
    required this.remainingSeconds,
    required this.onExtendSession,
    required this.onLogoutNow,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      title: Row(
        children: [
          Icon(Icons.warning, color: AppTheme.warningColor),
          const SizedBox(width: 8),
          Text(
            'Sesión por expirar',
            style: TextStyle(color: AppTheme.textPrimaryColor),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu sesión expirará en:',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: AppTheme.warningColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '¿Quieres extender la sesión?',
            style: TextStyle(color: AppTheme.textPrimaryColor),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onLogoutNow,
          child: Text(
            'Cerrar sesión',
            style: TextStyle(color: AppTheme.errorColor),
          ),
        ),
        ElevatedButton(
          onPressed: onExtendSession,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
          ),
          child: const Text('Extender sesión'),
        ),
      ],
    );
  }
}
