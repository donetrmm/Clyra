import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';

class SessionSettingsPage extends StatefulWidget {
  const SessionSettingsPage({super.key});

  @override
  State<SessionSettingsPage> createState() => _SessionSettingsPageState();
}

class _SessionSettingsPageState extends State<SessionSettingsPage> {
  late int _selectedTimeout;
  bool _isLoading = false;

  final List<int> _timeoutOptions = [1, 2, 3, 5, 10, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authViewModel = context.read<AuthViewModel>();
        setState(() {
          _selectedTimeout = authViewModel.sessionTimeoutMinutes;
        });
      }
    });
    _selectedTimeout = 5;
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    final authViewModel = context.read<AuthViewModel>();
    final success = await authViewModel.setSessionTimeout(_selectedTimeout);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${authViewModel.errorMessage}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _formatTimeout(int minutes) {
    if (minutes == 1) {
      return '1 minuto';
    } else if (minutes < 60) {
      return '$minutes minutos';
    } else {
      final hours = minutes ~/ 60;
      return '$hours hora${hours > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Configuración de Sesión'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSettings,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.textPrimaryColor,
                        ),
                      ),
                    )
                    : const Text(
                      'Guardar',
                      style: TextStyle(
                        color: AppTheme.accentBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<AuthViewModel>(
              builder: (context, authViewModel, child) {
                final stats = authViewModel.getSessionStats();
                return Card(
                  color: AppTheme.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado de la Sesión',
                          style: TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Icon(
                              stats['isActive']
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color:
                                  stats['isActive']
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              stats['isActive'] ? 'Activa' : 'Inactiva',
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        if (stats['isActive']) ...[
                          const SizedBox(height: 12),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.security,
                                color: AppTheme.accentBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Token: ${stats['sessionTokenPreview'] ?? 'No disponible'}',
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 14,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                stats['hasEncryptedStorage']
                                    ? Icons.lock
                                    : Icons.lock_open,
                                color:
                                    stats['hasEncryptedStorage']
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Almacén: ${stats['hasEncryptedStorage'] ? 'Encriptado' : 'No encriptado'}',
                                style: TextStyle(
                                  color:
                                      stats['hasEncryptedStorage']
                                          ? AppTheme.successColor
                                          : AppTheme.errorColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              'Tiempo de Inactividad',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona cuánto tiempo puede estar inactiva la aplicación antes de cerrar automáticamente la sesión.',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            ...(_timeoutOptions.map((timeout) {
              final isSelected = timeout == _selectedTimeout;
              return Card(
                color:
                    isSelected
                        ? AppTheme.accentColor.withOpacity(0.1)
                        : AppTheme.cardColor,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    _formatTimeout(timeout),
                    style: TextStyle(
                      color:
                          isSelected
                              ? AppTheme.accentColor
                              : AppTheme.textPrimaryColor,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  leading: Radio<int>(
                    value: timeout,
                    groupValue: _selectedTimeout,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTimeout = value;
                        });
                      }
                    },
                    activeColor: AppTheme.accentColor,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedTimeout = timeout;
                    });
                  },
                ),
              );
            }).toList()),

            const SizedBox(height: 24),

            Card(
              color: AppTheme.accentBlue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.accentBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Información de Seguridad',
                          style: TextStyle(
                            color: AppTheme.accentBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Consumer<AuthViewModel>(
                      builder: (context, authViewModel, child) {
                        final stats = authViewModel.getSessionStats();
                        return Text(
                          '• Token de sesión: Encriptado con AES-256\n'
                          '• Tiempo de actividad: Guardado encriptado\n'
                          '• Configuración: Almacenada de forma segura\n'
                          '• Estado del almacén: ${stats['hasEncryptedStorage'] ? 'Activo y encriptado' : 'Inactivo'}\n'
                          '• La sesión se cierra automáticamente por inactividad\n'
                          '• Cualquier interacción con la app reinicia el contador\n'
                          '• Los tiempos válidos van de 1 minuto a 1 hora',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
