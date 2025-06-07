import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../widgets/password_card.dart';
import '../viewmodels/password_viewmodel.dart';
import 'add_password_page.dart';
import 'edit_password_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      if (authViewModel.isLoggedIn) {
        context.read<PasswordViewModel>().loadPasswords();
      } else {
        context.go(AppRouter.login);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.logout();

    if (mounted) {
      context.go(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Clyra'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'change_master_password':
                  context.push(AppRouter.changeMasterPassword);
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'change_master_password',
                    child: Row(
                      children: [
                        Icon(
                          Icons.vpn_key,
                          size: 18,
                          color: AppTheme.accentBlue,
                        ),
                        const SizedBox(width: 8),
                        const Text('Cambiar Contraseña Maestra'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          size: 18,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      ],
                    ),
                  ),
                ],
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: null, 
            ),
          ),
        ],
      ),
      body: Consumer<PasswordViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
            );
          }

          if (viewModel.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar las contraseñas',
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.errorMessage,
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.loadPasswords(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Notificación de datos corruptos
              Consumer<PasswordViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.hasCorruptedPasswords) {
                    return Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.warningColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: AppTheme.warningColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Datos corruptos detectados',
                                  style: TextStyle(
                                    color: AppTheme.textPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Algunas contraseñas no se pueden desencriptar. Edítalas para actualizarlas.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Barra de búsqueda y filtros
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Campo de búsqueda
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar contraseñas...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    viewModel.clearSearch();
                                  },
                                )
                                : null,
                      ),
                      onChanged: (value) {
                        viewModel.searchPasswords(value);
                      },
                    ),

                    const SizedBox(height: 12),

                    // Filtros
                    Row(
                      children: [
                        FilterChip(
                          label: const Text('Favoritos'),
                          selected: viewModel.showFavoritesOnly,
                          onSelected: (selected) {
                            viewModel.toggleFavoritesFilter();
                          },
                          selectedColor: AppTheme.accentColor.withValues(
                            alpha: 0.3,
                          ),
                          checkmarkColor: AppTheme.textPrimaryColor,
                        ),
                        const SizedBox(width: 8),
                        if (viewModel.searchQuery.isNotEmpty ||
                            viewModel.showFavoritesOnly)
                          TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              viewModel.clearFilters();
                            },
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('Limpiar filtros'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lista de contraseñas
              Expanded(
                child:
                    viewModel.passwords.isEmpty
                        ? _buildEmptyState(viewModel)
                        : RefreshIndicator(
                          onRefresh: () => viewModel.loadPasswords(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: viewModel.passwords.length,
                            itemBuilder: (context, index) {
                              final password = viewModel.passwords[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: PasswordCard(
                                  password: password,
                                  onTap: () {
                                  },
                                  onFavoriteToggle: () {
                                    viewModel.toggleFavorite(password.id);
                                  },
                                  onEdit: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (context) => EditPasswordPage(
                                              password: password,
                                            ),
                                      ),
                                    );
                                  },
                                  onDelete: () {
                                    _showDeleteConfirmation(
                                      context,
                                      password.id,
                                      password.title,
                                      viewModel,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddPasswordPage()),
          );
        },
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.add, color: AppTheme.textPrimaryColor),
      ),
    );
  }

  Widget _buildEmptyState(PasswordViewModel viewModel) {
    if (viewModel.searchQuery.isNotEmpty || viewModel.showFavoritesOnly) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron contraseñas',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros términos de búsqueda',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security, size: 64, color: AppTheme.textSecondaryColor),
          const SizedBox(height: 16),
          Text(
            '¡Bienvenido a Clyra!',
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comienza agregando tu primera contraseña',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddPasswordPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar contraseña'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String passwordId,
    String title,
    PasswordViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: Text(
            'Eliminar contraseña',
            style: TextStyle(color: AppTheme.textPrimaryColor),
          ),
          content: Text(
            '¿Estás seguro de que quieres eliminar "$title"?',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                viewModel.deletePassword(passwordId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Contraseña "$title" eliminada'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              child: Text(
                'Eliminar',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
