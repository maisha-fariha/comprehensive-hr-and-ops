import 'package:get_it/get_it.dart';

/// Helper for common DI registration patterns
class DIHelper {
  /// Register repository with standard dependencies
  static void registerRepository<T extends Object>({
    required T Function() factory,
    bool lazy = true,
  }) {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<T>()) return;

    if (lazy) {
      getIt.registerLazySingleton<T>(factory);
    } else {
      getIt.registerSingleton<T>(factory());
    }
  }

  /// Register use case with repository dependency
  static void registerUseCase<U extends Object, R extends Object>({
    required U Function(R repository) factory,
    bool lazy = true,
  }) {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<U>()) return;

    if (lazy) {
      getIt.registerLazySingleton<U>(
        () => factory(getIt<R>()),
      );
    } else {
      getIt.registerSingleton<U>(factory(getIt<R>()));
    }
  }

  /// Register controller with dependencies.
  ///
  /// Controllers are always [registerFactory] — never GetIt singletons — so a
  /// new login cannot reuse another account's in-memory screen state via
  /// `Get.put(GetIt.instance<T>())`.
  static void registerController<T extends Object>({
    required T Function() factory,
    bool lazy = true,
  }) {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<T>()) {
      // Replace legacy lazy-singleton registrations from older builds.
      // unregister is sync unless a disposing Future is returned.
      final pending = getIt.unregister<T>();
      if (pending is Future) {
        pending.then((_) {
          if (!getIt.isRegistered<T>()) {
            getIt.registerFactory<T>(factory);
          }
        });
        return;
      }
    }
    if (!getIt.isRegistered<T>()) {
      getIt.registerFactory<T>(factory);
    }
  }

  /// Async variant that awaits unregister — prefer this in `setup*Dependencies`.
  static Future<void> registerControllerFactory<T extends Object>({
    required T Function() factory,
  }) async {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<T>()) {
      await getIt.unregister<T>();
    }
    getIt.registerFactory<T>(factory);
  }
}

