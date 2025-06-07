import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/password_entry.dart';
import '../../data/models/password_entry_model.dart';

class PasswordCard extends StatefulWidget {
  final PasswordEntry password;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const PasswordCard({
    super.key,
    required this.password,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onDelete,
    this.onEdit,
  });

  @override
  State<PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<PasswordCard> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final isCorrupted =
        widget.password is PasswordEntryModel &&
        (widget.password as PasswordEntryModel).isCorrupted;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration:
              isCorrupted
                  ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.warningColor, width: 2),
                  )
                  : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCorrupted) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: AppTheme.warningColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Datos corruptos - Edita para actualizar',
                            style: TextStyle(
                              color: AppTheme.warningColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Fila superior: título, favorito y menú
                Row(
                  children: [
                    // Icono de la aplicación
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getServiceIcon(widget.password.title),
                        color: AppTheme.accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Título
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.password.title,
                            style: TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.password.website != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.password.website!,
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Botón de favorito
                    IconButton(
                      onPressed: widget.onFavoriteToggle,
                      icon: Icon(
                        widget.password.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color:
                            widget.password.isFavorite
                                ? Colors.red
                                : AppTheme.textSecondaryColor,
                      ),
                    ),

                    // Menú de opciones
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'copy_username':
                            _copyToClipboard(
                              widget.password.username,
                              'Usuario copiado',
                            );
                            break;
                          case 'copy_password':
                            _copyToClipboard(
                              widget.password.password,
                              'Contraseña copiada',
                            );
                            break;
                          case 'edit':
                            if (widget.onEdit != null) {
                              widget.onEdit!();
                            }
                            break;
                          case 'delete':
                            widget.onDelete();
                            break;
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'copy_username',
                              child: Row(
                                children: [
                                  Icon(Icons.person, size: 18),
                                  SizedBox(width: 8),
                                  Text('Copiar usuario'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'copy_password',
                              child: Row(
                                children: [
                                  Icon(Icons.lock, size: 18),
                                  SizedBox(width: 8),
                                  Text('Copiar contraseña'),
                                ],
                              ),
                            ),
                            if (widget.onEdit != null) ...[
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: AppTheme.accentBlue,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Editar',
                                      style: TextStyle(
                                        color: AppTheme.accentBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: AppTheme.errorColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Eliminar',
                                    style: TextStyle(
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Información del usuario
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.password.username,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed:
                          () => _copyToClipboard(
                            widget.password.username,
                            'Usuario copiado',
                          ),
                      icon: Icon(
                        Icons.copy,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),

                // Información de la contraseña
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isPasswordVisible
                            ? widget.password.password
                            : '•' * widget.password.password.length,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                          fontFamily: _isPasswordVisible ? 'monospace' : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    IconButton(
                      onPressed:
                          () => _copyToClipboard(
                            widget.password.password,
                            'Contraseña copiada',
                          ),
                      icon: Icon(
                        Icons.copy,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),

                // Categoría y fecha 
                if (widget.password.category != null ||
                    widget.password.notes != null) ...[
                  const SizedBox(height: 8),

                  // Categoría
                  if (widget.password.category != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.password.category!,
                            style: TextStyle(
                              color: AppTheme.accentBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Notas
                  if (widget.password.notes != null &&
                      widget.password.notes!.isNotEmpty) ...[
                    if (widget.password.category != null)
                      const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.textMutedColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.note,
                                size: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Notas:',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.password.notes!,
                            style: TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 12,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getServiceIcon(String title) {
    final titleLower = title.toLowerCase();

    if (titleLower.contains('google') || titleLower.contains('gmail')) {
      return Icons.email;
    } else if (titleLower.contains('facebook')) {
      return Icons.facebook;
    } else if (titleLower.contains('twitter') || titleLower.contains('x.com')) {
      return Icons.alternate_email;
    } else if (titleLower.contains('instagram')) {
      return Icons.camera_alt;
    } else if (titleLower.contains('linkedin')) {
      return Icons.work;
    } else if (titleLower.contains('github')) {
      return Icons.code;
    } else if (titleLower.contains('netflix')) {
      return Icons.movie;
    } else if (titleLower.contains('spotify')) {
      return Icons.music_note;
    } else if (titleLower.contains('bank') || titleLower.contains('banco')) {
      return Icons.account_balance;
    } else if (titleLower.contains('amazon')) {
      return Icons.shopping_cart;
    } else {
      return Icons.language;
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}
