import 'package:royal_airlines/models/payment_model.dart';

/// PaymentStatus
/// -------------
/// Estado del proceso de pago simulado.
enum PaymentStatus { approved, declined }

class PaymentException implements Exception {
  const PaymentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PaymentResult {
  const PaymentResult({
    required this.status,
    required this.message,
  });

  final PaymentStatus status;
  final String message;

  bool get approved => status == PaymentStatus.approved;
}

/// PaymentService
/// --------------
/// Simula un proceso de pago bancario realista: valida el formato del
/// formulario, espera la latencia típica y decide aprobar o rechazar la
/// transacción. La UI nunca ve el número completo ni el CVV.
///
/// Este servicio SOLO se usa en modo mock (`useMockApi: true`). Cuando
/// hay backend real, [BookingRepository] usa en su lugar
/// [BookingService.confirmBooking], que llama al mismo endpoint
/// `/payments/confirm` con el campo `totalPrice` (ver
/// `docs/api-contract.md`). Mantener un único camino real evita que
/// el mismo endpoint reciba nombres de campo distintos según por dónde
/// se llame.
class PaymentService {
  Future<PaymentResult> processPayment({
    required PaymentModel payment,
    required double totalPrice,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));

    final cleanedNumber =
        payment.maskedCardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final hasValidCard = cleanedNumber.length >= 4;
    final hasValidName = payment.cardHolderName.trim().isNotEmpty;
    final hasValidExpiry =
        RegExp(r'^\d{2}/\d{2}$').hasMatch(payment.expiry.trim());

    if (!hasValidName || !hasValidCard || !hasValidExpiry || totalPrice <= 0) {
      throw const PaymentException(
          'La tarjeta no es válida para esta transacción.');
    }

    return const PaymentResult(
      status: PaymentStatus.approved,
      message: 'Pago aprobado correctamente.',
    );
  }
}
