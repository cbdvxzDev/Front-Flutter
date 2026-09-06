/// TravelClass
/// -----------
/// Clase de viaje. Vive en `models/` (no dentro de `features/home/`)
/// porque tanto el buscador de Home como la selección de tarifa en
/// Flights (y más adelante Booking) necesitan el mismo enum — antes
/// vivía en `home_controller.dart`, se movió aquí al volverse
/// compartido entre dos features (DRY).
enum TravelClass { economy, premiumEconomy, business, first }

/// Etiquetas legibles de [TravelClass], para no repetir un `switch`
/// de texto en cada widget que las muestre.
extension TravelClassLabel on TravelClass {
  String get label {
    switch (this) {
      case TravelClass.economy:
        return 'Económica';
      case TravelClass.premiumEconomy:
        return 'Económica Premium';
      case TravelClass.business:
        return 'Business';
      case TravelClass.first:
        return 'Primera Clase';
    }
  }

  /// Etiqueta corta, usada en espacios reducidos como [FareCard].
  String get shortLabel {
    switch (this) {
      case TravelClass.economy:
        return 'Económica';
      case TravelClass.premiumEconomy:
        return 'Premium';
      case TravelClass.business:
        return 'Business';
      case TravelClass.first:
        return 'Primera';
    }
  }

  /// Nombre estable (no traducible) usado para persistir en disco/JSON.
  /// Nunca usar [label]/[shortLabel] para esto: cambiarían el texto
  /// visible rompería la serialización guardada de reservas viejas.
  String get storageKey => name;
}

/// Reconstruye un [TravelClass] desde [TravelClass.storageKey]. Si el
/// valor guardado no coincide con ninguno (versión vieja de la app),
/// cae a [TravelClass.economy] en vez de lanzar una excepción.
TravelClass travelClassFromStorageKey(String key) {
  return TravelClass.values.firstWhere(
    (value) => value.name == key,
    orElse: () => TravelClass.economy,
  );
}
