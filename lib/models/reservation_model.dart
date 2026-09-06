import 'package:royal_airlines/models/flight_model.dart';
import 'package:royal_airlines/models/passenger_model.dart';
import 'package:royal_airlines/models/payment_model.dart';

/// ReservationModel
/// ----------------
/// Representa una reserva ya confirmada: el vuelo, la tarifa elegida,
/// los asientos, los pasajeros, el pago y el precio total. Es el
/// resultado final del flujo de Booking, y el modelo que va a listar
/// el módulo Reservations (tab "Mis Reservas") y el detalle en Profile.
class ReservationModel {
  final String id;
  final String confirmationCode;
  final FlightModel flight;
  final FareModel fare;
  final List<String> seats;
  final List<PassengerModel> passengers;
  final PaymentModel payment;
  final double totalPrice;
  final DateTime bookedAt;

  const ReservationModel({
    required this.id,
    required this.confirmationCode,
    required this.flight,
    required this.fare,
    required this.seats,
    required this.passengers,
    required this.payment,
    required this.totalPrice,
    required this.bookedAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String,
      confirmationCode: json['confirmationCode'] as String,
      flight: FlightModel.fromJson(json['flight'] as Map<String, dynamic>),
      fare: FareModel.fromJson(json['fare'] as Map<String, dynamic>),
      seats: (json['seats'] as List).cast<String>(),
      passengers: (json['passengers'] as List)
          .map((p) => PassengerModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      payment: PaymentModel.fromJson(json['payment'] as Map<String, dynamic>),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      bookedAt: DateTime.parse(json['bookedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'confirmationCode': confirmationCode,
      'flight': flight.toJson(),
      'fare': fare.toJson(),
      'seats': seats,
      'passengers': passengers.map((p) => p.toJson()).toList(),
      'payment': payment.toJson(),
      'totalPrice': totalPrice,
      'bookedAt': bookedAt.toIso8601String(),
    };
  }
}
