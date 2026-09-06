import 'dart:convert';

import 'package:royal_airlines/core/config/app_config.dart';
import 'package:royal_airlines/core/network/api_client.dart';
import 'package:royal_airlines/core/network/api_contracts.dart';
import 'package:royal_airlines/models/user_model.dart';
import 'package:royal_airlines/services/session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Excepción específica de autenticación, para que el controller pueda
/// distinguir "credenciales inválidas" de un error inesperado.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// _RegisteredUser
/// ---------------
/// Par usuario + contraseña guardado en la "base de datos" en memoria.
/// Privado del archivo: el resto de la app nunca ve la contraseña,
/// solo [UserModel].
class _RegisteredUser {
  final UserModel user;
  final String password;

  _RegisteredUser({required this.user, required this.password});
}

/// AuthService
/// -----------
/// Única responsable de "hablar" con la fuente de datos de autenticación.
/// Mock local — pero a diferencia de una versión anterior que solo
/// verificaba un usuario hardcodeado, esta SÍ persiste los usuarios que
/// se registran en una lista en memoria ([_registeredUsers]), para que
/// el ciclo completo registro -> logout -> login funcione de extremo a
/// extremo dentro de una misma sesión de la app.
///
/// "En memoria" significa que la lista se reinicia si la app se cierra
/// por completo (hot restart, cerrar la app) — eso es esperado en un
/// mock sin backend real; el día que exista uno, solo este archivo
/// cambia.
class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final SessionStorage _sessionStorage = SessionStorage();
  static const String _demoEmail = 'demo@royalairlines.com';
  static const String _demoPassword = 'Demo2026!';

  /// "Base de datos" en memoria de usuarios registrados durante esta
  /// sesión de la app. Se inicializa con una cuenta de ejemplo
  /// (demo@royalairlines.com / Demo2026!) para poder probar login sin
  /// depender de un backend real.
  final List<_RegisteredUser> _registeredUsers = [
    _RegisteredUser(
      user: const UserModel(
        id: 'usr_001',
        fullName: 'Alejandro Torres',
        email: _demoEmail,
        avatarUrl: null,
      ),
      password: _demoPassword,
    ),
  ];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final savedUsers = prefs.getStringList('registered_users') ?? [];
    for (final encoded in savedUsers) {
      final data = jsonDecode(encoded) as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _registeredUsers.add(_RegisteredUser(
        user: user,
        password: data['password'] as String,
      ));
    }
    _loaded = true;
  }

  Future<void> _saveRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final customUsers = _registeredUsers
        .where((entry) => entry.user.id != 'usr_001')
        .map((entry) => jsonEncode({
              'user': entry.user.toJson(),
              'password': entry.password,
            }))
        .toList();
    await prefs.setStringList('registered_users', customUsers);
  }

  Future<UserModel> login(
      {required String email, required String password}) async {
    if (!AppConfig.useMockApi) {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        body: {'email': email.trim(), 'password': password},
      );
      await _saveTokenFromResponse(response);
      return _userFromResponse(response);
    }

    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 900));

    final normalizedEmail = email.trim().toLowerCase();

    // Busca entre TODOS los usuarios registrados (demo + los que se
    // hayan creado con register()), no solo contra un correo fijo.
    final match = _registeredUsers.where(
      (entry) =>
          entry.user.email == normalizedEmail && entry.password == password,
    );

    if (match.isEmpty) {
      throw const AuthException('Correo o contraseña incorrectos');
    }

    return match.first.user;
  }

  Future<UserModel> socialLogin({required String provider}) async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 700));

    final email = '${provider.toLowerCase()}@royalairlines.com';
    final existing = _registeredUsers.where(
      (entry) => entry.user.email == email,
    );
    if (existing.isNotEmpty) return existing.first.user;

    final user = UserModel(
      id: 'social_${provider.toLowerCase()}',
      fullName: 'Usuario de $provider',
      email: email,
      avatarUrl: null,
    );
    _registeredUsers.add(_RegisteredUser(user: user, password: 'social'));
    await _saveRegisteredUsers();
    return user;
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (!AppConfig.useMockApi) {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        body: {
          'fullName': fullName.trim(),
          'email': email.trim(),
          'password': password,
        },
      );
      await _saveTokenFromResponse(response);
      return _userFromResponse(response);
    }

    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 1100));

    final normalizedEmail = email.trim().toLowerCase();

    final bool emailTaken =
        _registeredUsers.any((entry) => entry.user.email == normalizedEmail);
    if (emailTaken) {
      throw const AuthException('Ese correo ya está registrado');
    }

    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: normalizedEmail,
      avatarUrl: null,
    );

    // Aquí está la corrección clave: el usuario nuevo se GUARDA en la
    // lista, para que un login posterior con las mismas credenciales
    // lo encuentre.
    _registeredUsers.add(_RegisteredUser(user: newUser, password: password));
    await _saveRegisteredUsers();

    return newUser;
  }

  UserModel _userFromResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthException('La respuesta de autenticación no es válida');
    }

    final user = data['user'];
    if (user is! Map<String, dynamic>) {
      throw const AuthException('La respuesta no contiene el usuario');
    }
    return UserModel.fromJson(user);
  }

  Future<void> _saveTokenFromResponse(Map<String, dynamic> response) async {
    final data = response['data'];
    final token = data is Map<String, dynamic> ? data['token'] : null;
    if (token is! String || token.isEmpty) {
      throw const AuthException('La respuesta no contiene un token válido');
    }
    await _sessionStorage.saveToken(token);
  }

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.profile);
    return _userFromResponse(response);
  }

  /// Actualiza nombre/correo del usuario autenticado. Si cambia el
  /// correo, también actualiza la entrada en [_registeredUsers] para
  /// que un futuro login use el correo nuevo.
  Future<UserModel> updateProfile({
    required String userId,
    required String fullName,
    required String email,
  }) async {
    if (!AppConfig.useMockApi) {
      final response = await _apiClient.put(
        ApiEndpoints.profile,
        body: {
          'fullName': fullName.trim(),
          'email': email.trim(),
        },
      );
      return _userFromResponse(response);
    }

    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 700));

    final normalizedEmail = email.trim().toLowerCase();

    final emailTakenByOther = _registeredUsers.any(
      (entry) => entry.user.email == normalizedEmail && entry.user.id != userId,
    );
    if (emailTakenByOther) {
      throw const AuthException('Ese correo ya está en uso por otra cuenta');
    }

    final index =
        _registeredUsers.indexWhere((entry) => entry.user.id == userId);
    if (index == -1) {
      throw const AuthException('Usuario no encontrado');
    }

    final updatedUser = _registeredUsers[index].user.copyWith(
          fullName: fullName.trim(),
          email: normalizedEmail,
        );

    _registeredUsers[index] = _RegisteredUser(
      user: updatedUser,
      password: _registeredUsers[index].password,
    );
    await _saveRegisteredUsers();

    return updatedUser;
  }

  /// Cambia la contraseña del usuario identificado por [userId]. Antes
  /// esto solo comparaba contra una contraseña fija; ahora valida y
  /// actualiza la entrada real del usuario en [_registeredUsers].
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!AppConfig.useMockApi) {
      await _apiClient.post(
        ApiEndpoints.changePassword,
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return;
    }

    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 800));

    final index =
        _registeredUsers.indexWhere((entry) => entry.user.id == userId);
    if (index == -1) {
      throw const AuthException('Usuario no encontrado');
    }

    if (_registeredUsers[index].password != currentPassword) {
      throw const AuthException('La contraseña actual no es correcta');
    }

    _registeredUsers[index] = _RegisteredUser(
      user: _registeredUsers[index].user,
      password: newPassword,
    );
    await _saveRegisteredUsers();
  }

  /// Envía instrucciones de recuperación a [email]. Mock: siempre
  /// "tiene éxito" (no revela si el correo existe o no, práctica de
  /// seguridad estándar para no filtrar qué correos están registrados).
  Future<void> requestPasswordReset({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  Future<void> logout() async {
    await _sessionStorage.clear();
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
