import 'package:royal_airlines/core/network/api_client.dart';
import 'package:royal_airlines/core/network/api_contracts.dart';
import 'package:royal_airlines/models/payment_model.dart';
import 'package:royal_airlines/models/passenger_model.dart';

/// BookingService
/// --------------
/// Servicio para crear reservas. El backend real debería devolver un
/// identificador de reserva y un código de confirmación para que el flujo
/// de compra final pueda continuar al detalle de reserva.
class BookingService {
  BookingService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>> createBooking({
    required String flightId,
    required List<PassengerModel> passengers,
    required String fareType,
    required List<String> seats,
  }) async {
    final response = await _client.post(
      ApiEndpoints.bookings,
      body: {
        'flightId': flightId,
        'passengers': passengers
            .map((passenger) => {
                  'fullName': passenger.fullName,
                  'documentNumber': passenger.documentNumber,
                  'birthDate': passenger.birthDate.toIso8601String(),
                })
            .toList(),
        'fareType': fareType,
        'seats': seats,
      },
    );

    return response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> confirmBooking({
    required String bookingId,
    required PaymentModel payment,
    required double totalPrice,
  }) async {
    final response = await _client.post(
      ApiEndpoints.payments,
      body: {
        'bookingId': bookingId,
        'paymentMethod': 'card',
        'cardHolderName': payment.cardHolderName,
        'cardLastFour': _lastFourDigits(payment.maskedCardNumber),
        'expiry': payment.expiry,
        'amount': totalPrice,
        'currency': 'COP',
      },
    );

    return response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  String _lastFourDigits(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length <= 4 ? digits : digits.substring(digits.length - 4);
  }
}
