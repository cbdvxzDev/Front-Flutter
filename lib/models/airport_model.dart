/// AirportModel
/// ------------
/// Representa un aeropuerto/ciudad. Vive en `models/` (no dentro de
/// `features/home/`) porque no es exclusivo de Home: el selector de
/// origen/destino se reutiliza en Flights (filtros) y Booking
/// (resumen del pasaje). Mantenerlo aquí evita que cada feature
/// defina su propia versión (DRY).
class AirportModel {
  final String code; // Código IATA, ej. "BOG"
  final String city;
  final String country;
  final String airportName;

  const AirportModel({
    required this.code,
    required this.city,
    required this.country,
    required this.airportName,
  });

  /// Texto corto usado en los campos de búsqueda: "Bogotá (BOG)".
  String get shortLabel => '$city ($code)';

  factory AirportModel.fromJson(Map<String, dynamic> json) {
    return AirportModel(
      code: json['code'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      airportName: json['airportName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'city': city,
      'country': country,
      'airportName': airportName,
    };
  }
}
