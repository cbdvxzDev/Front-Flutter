/// AppConfig
/// ---------
/// Centraliza la configuración del entorno para evitar duplicar URLs,
/// claves o banderas entre servicios y widgets. Mantener aquí el valor
/// base permite pasar a un backend real sin tocar cada servicio por separado.
class AppConfig {
  AppConfig._();

  static const String appName = 'Royal Airlines';

  /// Ambiente activo de la app.
  static const AppEnvironment environment = AppEnvironment.dev;

  /// URL base del backend para el emulador Android.
  ///
  /// `10.0.2.2` apunta al computador anfitrión desde el emulador Android.
  /// En un teléfono físico se debe sustituir por la IP local del computador,
  /// por ejemplo `http://192.168.1.20:8080`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// Versión de la API.
  static const String apiVersion = 'v1';

  /// Permite trabajar con la interfaz antes de que el backend esté disponible.
  /// Al finalizar backend, cambia este valor a `false`.
  static const bool useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: true,
  );

  /// Base URL completa para las llamadas HTTP. Se deja como una sola
  /// fuente de verdad para que backend y frontend compartan el mismo
  /// contrato de rutas.
  static String get baseUrl => '$apiBaseUrl/$apiVersion';
}

enum AppEnvironment { dev, staging, prod }
