import 'package:royal_airlines/models/airport_model.dart';
import 'package:royal_airlines/models/flight_model.dart';
import 'package:royal_airlines/models/travel_class.dart';
import 'package:royal_airlines/core/config/app_config.dart';
import 'package:royal_airlines/services/flight_service.dart';

/// FlightRepository
/// -----------------
/// Única responsable de proveer los resultados de búsqueda de vuelos.
/// Cada vuelo trae 4 tarifas (Basic, Light, Full, Premium Economy),
/// estilo aerolínea real, cada una con su lista de beneficios y
/// SIEMPRE con cupo disponible — nunca se genera una tarifa agotada.
class FlightRepository {
  FlightRepository({FlightService? flightService})
      : _flightService = flightService ?? FlightService();

  final FlightService _flightService;

  static const List<String> _airlines = [
    'Royal Airlines',
    'SkyBridge',
    'Continental Wings',
    'AeroLatam Plus',
  ];

  static const List<String> _aircrafts = [
    'Airbus A320',
    'Boeing 737-800',
    'Airbus A319',
    'Embraer E190',
  ];

  Future<List<FlightModel>> searchFlights({
    required AirportModel origin,
    required AirportModel destination,
    required DateTime date,
  }) async {
    if (!AppConfig.useMockApi) {
      return _flightService.searchFlights(
        origin: origin.code,
        destination: destination.code,
        departureDate: date,
      );
    }

    await Future.delayed(const Duration(milliseconds: 900));

    return List.generate(6, (index) {
      final departure = DateTime(
        date.year,
        date.month,
        date.day,
        6 + index * 3,
        (index * 15) % 60,
      );
      final durationHours = 1 + (index % 4);
      final durationMinutes = 20 + (index * 11) % 40;
      final arrival = departure.add(
        Duration(hours: durationHours, minutes: durationMinutes),
      );
      final stops = index % 3 == 0 ? 0 : (index % 3 == 1 ? 1 : 2);
      final basePrice = 185000.0 + (index * 12000);

      return FlightModel(
        id: 'flight_${origin.code}_${destination.code}_$index',
        airline: _airlines[index % _airlines.length],
        flightNumber: 'RA-${100 + index * 7}',
        aircraft: _aircrafts[index % _aircrafts.length],
        origin: origin,
        destination: destination,
        departureTime: departure,
        arrivalTime: arrival,
        stops: stops,
        fares: _buildFares(basePrice),
      );
    });
  }

  /// Genera las 4 tarifas estándar, cada una con su lista de
  /// beneficios. Todas quedan con `seatsAvailable > 0` a propósito.
  List<FareModel> _buildFares(double basePrice) {
    return [
      FareModel(
        travelClass: TravelClass.economy,
        tierName: 'Basic',
        price: basePrice,
        seatsAvailable: 9,
        benefits: const [
          'Bolso o mochila',
          'Cambio con cargo + diferencia de precio',
          'No aplican beneficios por categorías de socios',
          'Acumulas menos: 1 punto calificable por dólar',
        ],
      ),
      FareModel(
        travelClass: TravelClass.economy,
        tierName: 'Light',
        price: basePrice * 1.24,
        seatsAvailable: 7,
        benefits: const [
          'Bolso o mochila',
          'Maleta pequeña 12 kg',
          'Cambio con cargo + diferencia de precio',
          'Postulación a upgrade de cabina con tramos',
          'Acumula más: 20 puntos calificables por dólar',
        ],
      ),
      FareModel(
        travelClass: TravelClass.economy,
        tierName: 'Full',
        price: basePrice * 1.48,
        seatsAvailable: 5,
        benefits: const [
          'Bolso o mochila',
          'Maleta pequeña 12 kg',
          '1 equipaje de bodega 23 kg',
          'Cambio sin cargo + diferencia de precio',
          'Devolución antes de la salida del primer vuelo',
          'Selección de asiento estándar',
          'Postulación a upgrade de cabina con tramos',
          'Acumula más: 20 puntos calificables por dólar',
        ],
      ),
      FareModel(
        travelClass: TravelClass.premiumEconomy,
        tierName: 'Premium Economy Standard',
        price: basePrice * 1.61,
        seatsAvailable: 4,
        benefits: const [
          'Bolso o mochila',
          'Maleta pequeña 16 kg',
          '1 equipaje de bodega 23 kg',
          'Cambio con cargo + diferencia de precio',
          'Sin devolución de pasaje',
          'Asiento del medio bloqueado',
          'Mejor oferta gastronómica',
          'Más espacio para tus piernas',
          'Embarque y desembarque prioritario',
          'Acumula más: 20 puntos calificables por dólar',
        ],
      ),
    ];
  }
}
