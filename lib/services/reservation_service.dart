import 'package:royal_airlines/core/network/api_client.dart';
import 'package:royal_airlines/core/network/api_contracts.dart';
import 'package:royal_airlines/models/airport_model.dart';
import 'package:royal_airlines/models/flight_model.dart';
import 'package:royal_airlines/models/passenger_model.dart';
import 'package:royal_airlines/models/payment_model.dart';
import 'package:royal_airlines/models/reservation_model.dart';
import 'package:royal_airlines/models/travel_class.dart';

/// ReservationService
/// ------------------
/// Servicio de historial y detalle de reservas. Está preparado para un
/// backend real, pero también soporta un modo mock sin romper la app.
class ReservationService {
  ReservationService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Lista las reservas del usuario autenticado.
  ///
  /// A propósito NO recibe `userId`: el backend identifica al usuario
  /// por el token de la sesión (`Authorization`), no por un parámetro
  /// de la URL — así se evita que un cliente pueda pedir las reservas
  /// de otra cuenta cambiando un query param.
  Future<List<ReservationModel>> fetchReservations() async {
    final response = await _client.get(ApiEndpoints.reservations);

    final data = response['data'];
    final items = data is List ? data : const <dynamic>[];
    return items
        .map((item) => _reservationFromMap(item as Map<String, dynamic>))
        .toList();
  }

  ReservationModel _reservationFromMap(Map<String, dynamic> json) {
    final flight = _flightFromMap(json['flight'] as Map<String, dynamic>);
    final fare = _fareFromMap(json['fare'] as Map<String, dynamic>);
    final payment = PaymentModel(
      cardHolderName: json['payment']['cardHolderName'] as String,
      maskedCardNumber: json['payment']['maskedCardNumber'] as String,
      expiry: json['payment']['expiry'] as String,
    );

    final passengers = (json['passengers'] as List? ?? const [])
        .map((item) => PassengerModel(
              fullName: item['fullName'] as String,
              documentNumber: item['documentNumber'] as String,
              birthDate:
                  DateTime.tryParse(item['birthDate'] as String? ?? '') ??
                      DateTime.now().subtract(const Duration(days: 365 * 30)),
            ))
        .toList();

    return ReservationModel(
      id: json['id'] as String,
      confirmationCode: json['confirmationCode'] as String,
      flight: flight,
      fare: fare,
      seats: (json['seats'] as List? ?? const []).cast<String>(),
      passengers: passengers,
      payment: payment,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      bookedAt: DateTime.parse(json['bookedAt'] as String),
    );
  }

  FlightModel _flightFromMap(Map<String, dynamic> json) {
    final origin =
        AirportModel.fromJson(json['origin'] as Map<String, dynamic>);
    final destination =
        AirportModel.fromJson(json['destination'] as Map<String, dynamic>);

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
      fares: [_fareFromMap(json['fare'] as Map<String, dynamic>)],
    );
  }

  FareModel _fareFromMap(Map<String, dynamic> json) {
    return FareModel(
      travelClass: _travelClassFromString(json['travelClass'] as String),
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
        return TravelClass.premiumEconomy;
      case 'business':
        return TravelClass.business;
      case 'first':
        return TravelClass.first;
      default:
        return TravelClass.economy;
    }
  }
}
