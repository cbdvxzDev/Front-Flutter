import 'package:royal_airlines/models/flight_model.dart';
import 'package:royal_airlines/models/passenger_model.dart';
import 'package:royal_airlines/models/payment_model.dart';
import 'package:royal_airlines/models/reservation_model.dart';
import 'package:royal_airlines/core/config/app_config.dart';
import 'package:royal_airlines/services/booking_service.dart';
import 'package:royal_airlines/services/payment_service.dart';

/// BookingRepository
/// -----------------
/// Única responsable de "confirmar" una reserva. Hoy es MOCK LOCAL:
/// simula la latencia de un pago/reserva real y genera un código de
/// confirmación determinístico. El día que exista un backend real de
/// pagos/reservas, solo este archivo cambia — [BookingController] no
/// se entera.
class BookingRepository {
  BookingRepository({
    PaymentService? paymentService,
    BookingService? bookingService,
  })  : _paymentService = paymentService ?? PaymentService(),
        _bookingService = bookingService ?? BookingService();

  final PaymentService _paymentService;
  final BookingService _bookingService;

  Future<ReservationModel> confirmBooking({
    required FlightModel flight,
    required FareModel fare,
    required List<String> seats,
    required List<PassengerModel> passengers,
    required PaymentModel payment,
    required double totalPrice,
  }) async {
    if (!AppConfig.useMockApi) {
      final booking = await _bookingService.createBooking(
        flightId: flight.id,
        passengers: passengers,
        fareType: fare.travelClass.name,
        seats: seats,
      );
      final bookingId = booking['bookingId'] as String?;
      if (bookingId == null || bookingId.isEmpty) {
        throw const PaymentException(
            'El backend no devolvió el identificador de reserva.');
      }

      final paymentResponse = await _bookingService.confirmBooking(
        bookingId: bookingId,
        payment: payment,
        totalPrice: totalPrice,
      );
      if (paymentResponse['status'] != 'approved') {
        throw const PaymentException(
            'Pago rechazado por la entidad financiera.');
      }

      final reservationId =
          paymentResponse['reservationId'] as String? ?? bookingId;
      final confirmationCode =
          paymentResponse['confirmationCode'] as String? ?? reservationId;
      return ReservationModel(
        id: reservationId,
        confirmationCode: confirmationCode,
        flight: flight,
        fare: fare,
        seats: seats,
        passengers: passengers,
        payment: payment,
        totalPrice: totalPrice,
        bookedAt: DateTime.now(),
      );
    }

    final paymentResult = await _paymentService.processPayment(
      payment: payment,
      totalPrice: totalPrice,
    );

    if (!paymentResult.approved) {
      throw const PaymentException('Pago rechazado por la entidad financiera.');
    }

    await Future.delayed(const Duration(milliseconds: 700));

    final now = DateTime.now();
    final id = 'res_${now.millisecondsSinceEpoch}';

    return ReservationModel(
      id: id,
      confirmationCode: _generateConfirmationCode(id),
      flight: flight,
      fare: fare,
      seats: seats,
      passengers: passengers,
      payment: payment,
      totalPrice: totalPrice,
      bookedAt: now,
    );
  }

  /// Genera un código de confirmación estilo aerolínea (6 caracteres
  /// alfanuméricos en mayúscula), derivado del id para que sea
  /// determinístico y fácil de depurar durante el desarrollo.
  String _generateConfirmationCode(String seed) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final hash = seed.hashCode.abs();
    final buffer = StringBuffer();
    var value = hash;
    for (var i = 0; i < 6; i++) {
      buffer.write(chars[value % chars.length]);
      value ~/= chars.length;
    }
    return buffer.toString();
  }
}
