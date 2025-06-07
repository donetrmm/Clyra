import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/database_service.dart';
import '../storage/encryption_service.dart';

import '../../features/auth/data/datasources/local/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';

import '../../features/passwords/data/datasources/local/password_local_datasource.dart';
import '../../features/passwords/data/repositories/password_repository_impl.dart';
import '../../features/passwords/domain/repositories/password_repository.dart';
import '../../features/passwords/presentation/viewmodels/password_viewmodel.dart';

final sl = GetIt.instance; 

class InjectionContainer {
  static Future<void> init() async {
    // shared preferences
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerLazySingleton(() => sharedPreferences);

    // core services
    sl.registerLazySingleton<DatabaseService>(() => DatabaseService.instance);
    sl.registerLazySingleton<EncryptionService>(
      () => EncryptionService.instance,
    );

    // auth
    sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(
        databaseService: sl(),
        encryptionService: sl(),
        sharedPreferences: sl(),
      ),
    );

    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(localDataSource: sl()),
    );

    sl.registerFactory(
      () => AuthViewModel(authRepository: sl(), encryptionService: sl()),
    );

    // password
    sl.registerLazySingleton<PasswordLocalDataSource>(
      () => PasswordLocalDataSourceImpl(
        databaseService: sl(),
        encryptionService: sl(),
      ),
    );

    sl.registerLazySingleton<PasswordRepository>(
      () => PasswordRepositoryImpl(localDataSource: sl()),
    );

    sl.registerFactory(() => PasswordViewModel(passwordRepository: sl()));
  }

  static void reset() {
    sl.reset();
  }
}
