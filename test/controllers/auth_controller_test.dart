import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:royal_airlines/features/auth/controller/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pruebas de [AuthController] usando el [AuthService] real, pero en
/// modo mock (AppConfig.useMockApi == true, valor fijo del proyecto),
/// para validar la lógica de estado sin depender de red.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // flutter_secure_storage usa un MethodChannel nativo que no existe
  // en el entorno de test; se simula en memoria para que
  // SessionStorage pueda guardar/leer el token durante los tests.
  final secureStorageValues = <String, String>{};
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'write':
        final args = call.arguments as Map;
        secureStorageValues[args['key'] as String] = args['value'] as String;
        return null;
      case 'read':
        final args = call.arguments as Map;
        return secureStorageValues[args['key'] as String];
      case 'delete':
        final args = call.arguments as Map;
        secureStorageValues.remove(args['key'] as String);
        return null;
      case 'deleteAll':
        secureStorageValues.clear();
        return null;
      case 'readAll':
        return secureStorageValues;
      case 'containsKey':
        final args = call.arguments as Map;
        return secureStorageValues.containsKey(args['key'] as String);
      default:
        return null;
    }
  });

  setUp(() {
    // Cada test arranca con SharedPreferences y secure storage
    // vacíos, para que un registro hecho en un test no contamine a
    // los demás.
    SharedPreferences.setMockInitialValues({});
    secureStorageValues.clear();
  });

  group('AuthController - login', () {
    test('login con la cuenta demo válida deja status success', () async {
      final controller = AuthController();
      await controller.login(
        email: 'demo@royalairlines.com',
        password: 'Demo2026!',
      );

      expect(controller.status, AuthStatus.success);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser, isNotNull);
    });

    test('login con credenciales inválidas deja status error', () async {
      final controller = AuthController();
      await controller.login(
        email: 'demo@royalairlines.com',
        password: 'contraseña-incorrecta',
      );

      expect(controller.status, AuthStatus.error);
      expect(controller.errorMessage, isNotNull);
      expect(controller.isAuthenticated, isFalse);
    });
  });

  group('AuthController - registro', () {
    test('un usuario nuevo se registra correctamente', () async {
      final controller = AuthController();
      await controller.register(
        fullName: 'Pasajero Nuevo',
        email: 'nuevo_${DateTime.now().microsecondsSinceEpoch}@test.com',
        password: 'Demo2026!',
      );

      expect(controller.registerStatus, AuthStatus.success);
      expect(controller.currentUser, isNotNull);
    });

    test('registrar dos veces el mismo correo falla la segunda vez', () async {
      final email = 'repetido_${DateTime.now().microsecondsSinceEpoch}@test.com';
      final controller = AuthController();

      await controller.register(
        fullName: 'Primero',
        email: email,
        password: 'Demo2026!',
      );
      expect(controller.registerStatus, AuthStatus.success);

      final secondController = AuthController();
      await secondController.register(
        fullName: 'Segundo',
        email: email,
        password: 'otra-clave',
      );
      expect(secondController.registerStatus, AuthStatus.error);
      expect(secondController.registerErrorMessage, isNotNull);
    });
  });

  group('AuthController - sesión', () {
    test('logout limpia el usuario actual y el status', () async {
      final controller = AuthController();
      await controller.login(
        email: 'demo@royalairlines.com',
        password: 'Demo2026!',
      );
      expect(controller.isAuthenticated, isTrue);

      await controller.logout();

      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
      expect(controller.status, AuthStatus.idle);
    });

    test('tryRestoreSession recupera la sesión guardada tras login', () async {
      final controller = AuthController();
      await controller.login(
        email: 'demo@royalairlines.com',
        password: 'Demo2026!',
      );

      // Simula "reabrir la app": un controller nuevo debe recuperar
      // la sesión guardada en SharedPreferences por el login anterior.
      final restoredController = AuthController();
      expect(restoredController.isAuthenticated, isFalse);
      await restoredController.tryRestoreSession();

      expect(restoredController.isAuthenticated, isTrue);
      expect(restoredController.currentUser?.email, 'demo@royalairlines.com');
    });

    test('tryRestoreSession no recupera una sesión ya expirada', () async {
      final controller = AuthController();
      await controller.login(
        email: 'demo@royalairlines.com',
        password: 'Demo2026!',
      );
      expect(controller.isAuthenticated, isTrue);

      // Simula que la sesión se guardó hace más tiempo del permitido
      // (SessionStorage.sessionDuration), como si el usuario hubiera
      // dejado la app instalada sin abrirla por semanas.
      final prefs = await SharedPreferences.getInstance();
      final longAgo = DateTime.now().subtract(const Duration(days: 30));
      await prefs.setString(
        'session_login_at',
        longAgo.toIso8601String(),
      );

      final restoredController = AuthController();
      await restoredController.tryRestoreSession();

      expect(restoredController.isAuthenticated, isFalse);
      expect(restoredController.currentUser, isNull);
    });
  });
}
