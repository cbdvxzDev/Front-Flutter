import 'package:flutter/foundation.dart';
import 'package:royal_airlines/core/config/app_config.dart';
import 'package:royal_airlines/models/user_model.dart';
import 'package:royal_airlines/services/auth_service.dart';
import 'package:royal_airlines/services/session_storage.dart';

/// AuthStatus
/// ----------
enum AuthStatus { idle, loading, success, error }

/// ProfileUpdateStatus
/// -------------------
enum ProfileUpdateStatus { idle, loading, success, error }

/// AuthController
/// --------------
/// Gestor de estado de autenticación y perfil. Ahora persiste la
/// sesión en disco vía [SessionStorage]: al iniciar sesión, registrar
/// una cuenta o editar el perfil, guarda el usuario localmente para
/// que [tryRestoreSession] pueda recuperarlo automáticamente la
/// próxima vez que se abra la app — sin pedir credenciales de nuevo,
/// igual que apps como Instagram o Steam. La sesión solo se borra al
/// llamar [logout] explícitamente.
class AuthController extends ChangeNotifier {
  AuthController({AuthService? authService, SessionStorage? sessionStorage})
      : _authService = authService ?? AuthService(),
        _sessionStorage = sessionStorage ?? SessionStorage();

  final AuthService _authService;
  final SessionStorage _sessionStorage;

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  bool _rememberMe = false;
  UserModel? _currentUser;
  bool _isGuest = false;

  AuthStatus _registerStatus = AuthStatus.idle;
  String? _registerErrorMessage;

  ProfileUpdateStatus _profileStatus = ProfileUpdateStatus.idle;
  String? _profileErrorMessage;

  /// `true` mientras se está comprobando si hay una sesión guardada al
  /// arrancar la app. Evita parpadeos de UI que
  /// asuman "no autenticado" antes de terminar de leer el storage.
  bool _isRestoringSession = true;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get rememberMe => _rememberMe;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated =>
      _status == AuthStatus.success && _currentUser != null;
  bool get isGuest => _isGuest;
  bool get isRestoringSession => _isRestoringSession;

  AuthStatus get registerStatus => _registerStatus;
  String? get registerErrorMessage => _registerErrorMessage;
  bool get isRegisterLoading => _registerStatus == AuthStatus.loading;

  ProfileUpdateStatus get profileStatus => _profileStatus;
  String? get profileErrorMessage => _profileErrorMessage;
  bool get isProfileLoading => _profileStatus == ProfileUpdateStatus.loading;

  void toggleRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void continueAsGuest() {
    _isGuest = true;
    notifyListeners();
  }

  /// Intenta recuperar una sesión guardada en el dispositivo. Se llama
  /// UNA vez al arrancar la app, antes de mostrar la pantalla inicial.
  /// Si hay un usuario guardado, la app entra directo sin pedir login;
  /// si no, el flujo normal (Login) continúa igual.
  Future<void> tryRestoreSession() async {
    final savedUser = await _sessionStorage.loadUser();
    if (savedUser != null) {
      if (!AppConfig.useMockApi) {
        try {
          _currentUser = await _authService.getProfile();
          _status = AuthStatus.success;
          _isGuest = false;
        } on AuthException {
          await _sessionStorage.clear();
        }
      } else {
        _currentUser = savedUser;
        _status = AuthStatus.success;
        _isGuest = false;
      }
    }
    _isRestoringSession = false;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(email: email, password: password);
      _currentUser = user;
      _status = AuthStatus.success;
      _errorMessage = null;
      _isGuest = false;
      await _sessionStorage.saveUser(user);
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
    notifyListeners();
  }

  Future<void> loginWithProvider(String provider) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.socialLogin(provider: provider);
      _currentUser = user;
      _status = AuthStatus.success;
      _isGuest = false;
      await _sessionStorage.saveUser(user);
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'No se pudo iniciar sesión con $provider.';
    }
    notifyListeners();
  }

  void resetStatus() {
    _status = AuthStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _registerStatus = AuthStatus.loading;
    _registerErrorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(
          fullName: fullName, email: email, password: password);
      _currentUser = user;
      _registerStatus = AuthStatus.success;
      _registerErrorMessage = null;
      _status = AuthStatus.success;
      _errorMessage = null;
      _isGuest = false;
      await _sessionStorage.saveUser(user);
    } on AuthException catch (e) {
      _registerStatus = AuthStatus.error;
      _registerErrorMessage = e.message;
    } catch (_) {
      _registerStatus = AuthStatus.error;
      _registerErrorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
    notifyListeners();
  }

  void resetRegisterStatus() {
    _registerStatus = AuthStatus.idle;
    _registerErrorMessage = null;
    notifyListeners();
  }

  Future<void> updateProfile(
      {required String fullName, required String email}) async {
    final user = _currentUser;
    if (user == null) return;

    _profileStatus = ProfileUpdateStatus.loading;
    _profileErrorMessage = null;
    notifyListeners();

    try {
      final updated = await _authService.updateProfile(
        userId: user.id,
        fullName: fullName,
        email: email,
      );
      _currentUser = updated;
      _profileStatus = ProfileUpdateStatus.success;
      // Actualiza también la sesión guardada, para que el nombre/correo
      // nuevo persista tras cerrar y reabrir la app.
      await _sessionStorage.saveUser(updated);
    } on AuthException catch (e) {
      _profileStatus = ProfileUpdateStatus.error;
      _profileErrorMessage = e.message;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    _profileStatus = ProfileUpdateStatus.loading;
    _profileErrorMessage = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        userId: user.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _profileStatus = ProfileUpdateStatus.success;
    } on AuthException catch (e) {
      _profileStatus = ProfileUpdateStatus.error;
      _profileErrorMessage = e.message;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  void resetProfileStatus() {
    _profileStatus = ProfileUpdateStatus.idle;
    _profileErrorMessage = null;
    notifyListeners();
  }

  Future<void> requestPasswordReset({required String email}) async {
    await _authService.requestPasswordReset(email: email);
  }

  /// Cierra sesión: borra tanto el estado en memoria como la sesión
  /// guardada en disco. Es la ÚNICA forma en que la app vuelve a pedir
  /// login — nunca por cerrar/reabrir la app.
  Future<void> logout() async {
    await _authService.logout();
    await _sessionStorage.clear();
    _currentUser = null;
    _status = AuthStatus.idle;
    _errorMessage = null;
    _isGuest = false;
    notifyListeners();
  }
}
