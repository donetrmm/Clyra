import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../utils/generators/password_generator_service.dart';
import '../viewmodels/password_viewmodel.dart';
import '../../domain/entities/password_entry.dart';

class EditPasswordPage extends StatefulWidget {
  final PasswordEntry password;

  const EditPasswordPage({super.key, required this.password});

  @override
  State<EditPasswordPage> createState() => _EditPasswordPageState();
}

class _EditPasswordPageState extends State<EditPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _websiteController;
  late final TextEditingController _notesController;
  late final TextEditingController _categoryController;

  bool _isPasswordVisible = false;
  bool _showPasswordGenerator = false;
  PasswordStrength _passwordStrength = PasswordStrength.veryWeak;

  // Configuración del generador
  int _passwordLength = 16;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  bool _excludeSimilar = false;

  final List<String> _categories = [
    'Redes Sociales',
    'Correo Electrónico',
    'Trabajo',
    'Entretenimiento',
    'Compras',
    'Banca',
    'Educación',
    'Salud',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.password.title);
    _usernameController = TextEditingController(text: widget.password.username);
    _passwordController = TextEditingController(text: widget.password.password);
    _websiteController = TextEditingController(
      text: widget.password.website ?? '',
    );
    _notesController = TextEditingController(text: widget.password.notes ?? '');
    _categoryController = TextEditingController(
      text: widget.password.category ?? '',
    );

    _onPasswordChanged(widget.password.password);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String password) {
    setState(() {
      _passwordStrength = PasswordGeneratorService.checkPasswordStrength(
        password,
      );
    });
  }

  void _generatePassword() {
    final password = PasswordGeneratorService.generatePassword(
      length: _passwordLength,
      includeUppercase: _includeUppercase,
      includeLowercase: _includeLowercase,
      includeNumbers: _includeNumbers,
      includeSymbols: _includeSymbols,
      excludeSimilar: _excludeSimilar,
    );

    setState(() {
      _passwordController.text = password;
      _onPasswordChanged(password);
    });
  }

  Color _getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return AppTheme.errorColor;
      case PasswordStrength.weak:
        return AppTheme.warningColor;
      case PasswordStrength.medium:
        return Colors.yellow;
      case PasswordStrength.strong:
        return AppTheme.successColor;
      case PasswordStrength.veryStrong:
        return AppTheme.accentTeal;
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<PasswordViewModel>();

    final updatedPassword = widget.password.copyWith(
      title: _titleController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      website:
          _websiteController.text.trim().isEmpty
              ? null
              : _websiteController.text.trim(),
      notes:
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
      category:
          _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
      updatedAt: DateTime.now(),
    );

    await viewModel.updatePassword(updatedPassword);

    if (viewModel.isSuccess && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada exitosamente'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else if (viewModel.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${viewModel.errorMessage}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Editar Contraseña'),
        actions: [
          Consumer<PasswordViewModel>(
            builder: (context, viewModel, child) {
              return TextButton(
                onPressed: viewModel.isLoading ? null : _updatePassword,
                child:
                    viewModel.isLoading
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
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  hintText: 'Ej: Gmail, Facebook, Netflix',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Usuario/Email
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario/Email *',
                  hintText: 'usuario@ejemplo.com',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El usuario es obligatorio';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                onChanged: _onPasswordChanged,
                decoration: InputDecoration(
                  labelText: 'Contraseña *',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.auto_awesome),
                        onPressed: () {
                          setState(() {
                            _showPasswordGenerator = !_showPasswordGenerator;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La contraseña es obligatoria';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),

              // Indicador de fortaleza
              if (_passwordController.text.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      'Fortaleza: ',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      PasswordGeneratorService.getStrengthText(
                        _passwordStrength,
                      ),
                      style: TextStyle(
                        color: _getStrengthColor(_passwordStrength),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (_passwordStrength.index + 1) / 5,
                  backgroundColor: AppTheme.surfaceColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStrengthColor(_passwordStrength),
                  ),
                ),
              ],

              // Generador de contraseñas
              if (_showPasswordGenerator) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: AppTheme.accentBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Generador de Contraseñas',
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Longitud
                        Row(
                          children: [
                            Text(
                              'Longitud: $_passwordLength',
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: _passwordLength.toDouble(),
                                min: 8,
                                max: 32,
                                divisions: 24,
                                activeColor: AppTheme.accentBlue,
                                inactiveColor: AppTheme.textMutedColor
                                    .withValues(alpha: 0.3),
                                onChanged: (value) {
                                  setState(() {
                                    _passwordLength = value.round();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        // Opciones
                        CheckboxListTile(
                          title: Text(
                            'Mayúsculas (A-Z)',
                            style: TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 14,
                            ),
                          ),
                          value: _includeUppercase,
                          onChanged: (value) {
                            setState(() {
                              _includeUppercase = value ?? true;
                            });
                          },
                          dense: true,
                          activeColor: AppTheme.accentBlue,
                        ),
                        CheckboxListTile(
                          title: Text(
                            'Minúsculas (a-z)',
                            style: TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 14,
                            ),
                          ),
                          value: _includeLowercase,
                          onChanged: (value) {
                            setState(() {
                              _includeLowercase = value ?? true;
                            });
                          },
                          dense: true,
                          activeColor: AppTheme.accentBlue,
                        ),
                        CheckboxListTile(
                          title: Text(
                            'Números (0-9)',
                            style: TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 14,
                            ),
                          ),
                          value: _includeNumbers,
                          onChanged: (value) {
                            setState(() {
                              _includeNumbers = value ?? true;
                            });
                          },
                          dense: true,
                          activeColor: AppTheme.accentBlue,
                        ),
                        CheckboxListTile(
                          title: Text(
                            'Símbolos (!@#\$...)',
                            style: TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 14,
                            ),
                          ),
                          value: _includeSymbols,
                          onChanged: (value) {
                            setState(() {
                              _includeSymbols = value ?? true;
                            });
                          },
                          dense: true,
                          activeColor: AppTheme.accentBlue,
                        ),
                        CheckboxListTile(
                          title: Text(
                            'Excluir caracteres similares',
                            style: TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Evita 0, O, l, 1, etc.',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                          value: _excludeSimilar,
                          onChanged: (value) {
                            setState(() {
                              _excludeSimilar = value ?? false;
                            });
                          },
                          dense: true,
                          activeColor: AppTheme.accentBlue,
                        ),

                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _generatePassword,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Generar Nueva Contraseña'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Sitio web
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Sitio web',
                  hintText: 'https://ejemplo.com',
                  prefixIcon: Icon(Icons.language),
                ),
              ),

              const SizedBox(height: 16),

              // Categoría
              DropdownButtonFormField<String>(
                value:
                    _categoryController.text.isEmpty
                        ? null
                        : _categoryController.text,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                ),
                items:
                    _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                onChanged: (value) {
                  _categoryController.text = value ?? '';
                },
              ),

              const SizedBox(height: 16),

              // Notas
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  hintText: 'Información adicional...',
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
