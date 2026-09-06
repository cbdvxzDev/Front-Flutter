import 'package:royal_airlines/core/network/api_client.dart';
import 'package:royal_airlines/core/network/api_contracts.dart';
import 'package:royal_airlines/models/airport_model.dart';
import 'package:royal_airlines/models/flight_model.dart';
import 'package:royal_airlines/models/travel_class.dart';

/// FlightService
/// -------------
/// Servicio HTTP para buscar vuelos. Está listo para consumir el backend
/// real cuando se desactive el modo mock de AppConfig.
class FlightService {
  FlightService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<FlightModel>> searchFlights({
    required String origin,
    required String destination,
    required DateTime departureDate,
    DateTime? returnDate,
    int passengers = 1,
  }) async {
    final response = await _client.get(
      ApiEndpoints.flightsSearch,
      queryParameters: {
        'origin': origin,
        'destination': destination,
        'departureDate': departureDate.toIso8601String(),
        if (returnDate != null) 'returnDate': returnDate.toIso8601String(),
        'passengers': passengers.toString(),
      },
    );

    final data = response['data'];
    final items = data is List ? data : const <dynamic>[];
    return items
        .map((item) => _flightFromMap(item as Map<String, dynamic>))
        .toList();
  }

  FlightModel _flightFromMap(Map<String, dynamic> json) {
    final origin =
        AirportModel.fromJson(json['origin'] as Map<String, dynamic>);
    final destination =
        AirportModel.fromJson(json['destination'] as Map<String, dynamic>);

    final fares = (json['fares'] as List? ?? const [])
        .map((item) => _fareFromMap(item as Map<String, dynamic>))
        .toList();

    return FlightModel(
      id: json['id'] as String,
      airline: json['airline'] as String,
      flightNumber: json['flightNumber'] as String,
      aircraft: json['aircraft'] as String,
      origin: origin,
      destination: destination,
      departureTime: DateTime.parse(json['departureTime'] as String),
      arrivalTime: DateTime.parse(json['arrivalTime'] as String),
      stops: json['stops'] as int? ?? 0,
      fares: fares,
    );
  }

  FareModel _fareFromMap(Map<String, dynamic> json) {
    final travelClass = _travelClassFromString(json['travelClass'] as String);
    return FareModel(
      travelClass: travelClass,
      tierName: json['tierName'] as String,
      price: (json['price'] as num).toDouble(),
      seatsAvailable: json['seatsAvailable'] as int? ?? 0,
      benefits: (json['benefits'] as List? ?? const []).cast<String>(),
    );
  }

  TravelClass _travelClassFromString(String value) {
    switch (value.toLowerCase()) {
      case 'economy':
        return TravelClass.economy;
      case 'premium_economy':
      case 'premiumeconomy':
        return TravelClass.premiumEconomy;
      case 'business':
        return TravelClass.business;
      case 'first':
      case 'first_class':
        return TravelClass.first;
      default:
        return TravelClass.economy;
    }
  }
}
