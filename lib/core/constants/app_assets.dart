/// AppAssets
/// ---------
/// Centraliza las rutas de los assets declarados en `assets/images/`.
/// Evita strings mágicos como `'assets/images/logo.png'` repetidos en
/// múltiples pantallas, y sirve de único punto de actualización si un
/// archivo cambia de nombre.
class AppAssets {
  AppAssets._();

  static const String _imagesPath = 'assets/images';

  static const String logo = '$_imagesPath/logo.png';
}
