import 'package:flutter/foundation.dart';
import 'package:royal_airlines/features/booking/repository/booking_repository.dart';
import 'package:royal_airlines/models/flight_model.dart';
import 'package:royal_airlines/models/passenger_model.dart';
import 'package:royal_airlines/models/payment_model.dart';
import 'package:royal_airlines/models/reservation_model.dart';
import 'package:royal_airlines/models/seat_pricing.dart';

/// BaggageOption
/// -------------
/// Opciones de equipaje adicional disponibles en el checkout.
enum BaggageOption { included, extra10kg, extra20kg }

/// Precio adicional de cada [BaggageOption], y su etiqueta legible.
/// Valores en pesos colombianos (COP), consistentes con el resto de
/// la app (tarifas de vuelo y cargos de asiento).
extension BaggageOptionInfo on BaggageOption {
  String get label {
    switch (this) {
      case BaggageOption.included:
        return 'Equipaje incluido';
      case BaggageOption.extra10kg:
        return '+10 kg extra';
      case BaggageOption.extra20kg:
        return '+20 kg extra';
    }
  }

  double get price {
    switch (this) {
      case BaggageOption.included:
        return 0;
      case BaggageOption.extra10kg:
        return 15000;
      case BaggageOption.extra20kg:
        return 30000;
    }
  }
}

/// BookingStatus
/// -------------
/// Estado del proceso de confirmación de la reserva.
enum BookingStatus { idle, loading, success, error }

/// BookingController
/// -------------------
/// Gestor de estado de todo el flujo de Booking. Mantiene la selección
/// interactiva (tarifa, asientos, equipaje) como estado reactivo, ya
/// que varios widgets (FareSelector, SeatSelector, BaggageSelector,
/// BookingSummary) necesitan reaccionar a estos cambios en tiempo real.
///
/// Los datos de FORMULARIO (pasajeros, tarjeta) NO viven aquí — se
/// mantienen como `TextEditingController`s locales en [BookingScreen]
/// (mismo patrón que [LoginForm]/[RegisterForm]) y solo se entregan a
/// este controller, ya convertidos a modelos, al confirmar la reserva.
/// Esto evita reconstruir toda la pantalla en cada tecla presionada.
class BookingController extends ChangeNotifier {
  BookingController({
    required this.flight,
    required FareModel initialFare,
    required this.requiredSeatCount,
    BookingRepository? repository,
  })  : _selectedFare = initialFare,
        _repository = repository ?? BookingRepository();

  final FlightModel flight;
  final int requiredSeatCount;
  final BookingRepository _repository;

  FareModel _selectedFare;
  final List<String> _selectedSeats = [];
  BaggageOption _baggageOption = BaggageOption.included;
  bool _travelInsurance = false;
  bool _priorityBoarding = false;

  BookingStatus _status = BookingStatus.idle;
  String? _errorMessage;
  ReservationModel? _reservation;

  FareModel get selectedFare => _selectedFare;
  List<String> get selectedSeats => List.unmodifiable(_selectedSeats);
  BaggageOption get baggageOption => _baggageOption;
  bool get hasTravelInsurance => _travelInsurance;
  bool get hasPriorityBoarding => _priorityBoarding;
  BookingStatus get status => _status;
  String? get errorMessage => _errorMessage;
  ReservationModel? get reservation => _reservation;
  bool get isLoading => _status == BookingStatus.loading;

  bool get hasRequiredSeats => _selectedSeats.length == requiredSeatCount;

  /// Subtotal de la tarifa (precio por pasajero x cantidad de pasajeros).
  double get fareSubtotal => _selectedFare.price * requiredSeatCount;

  /// Cargo total por los asientos elegidos, según la zona de cada uno
  /// ([SeatPricing]). Se recalcula cada vez que cambia la selección.
  double get seatCharge => _selectedSeats.fold<double>(
        0,
        (sum, code) => sum + SeatPricing.categoryForSeat(code).price,
      );

  /// Extras opcionales de la reserva: seguro y embarque prioritario.
  double get travelExtrasPrice {
    var total = 0.0;
    if (_travelInsurance) total += 25000;
    if (_priorityBoarding) total += 18000;
    return total;
  }

  /// Precio total: tarifa por pasajero + cargo de asientos + equipaje
  /// adicional + extras opcionales.
  double get totalPrice =>
      fareSubtotal + seatCharge + _baggageOption.price + travelExtrasPrice;

  void setFare(FareModel fare) {
    _selectedFare = fare;
    notifyListeners();
  }

  /// Alterna la selección de un asiento. Si ya se alcanzó el máximo
  /// requerido y se toca uno nuevo (no seleccionado), no hace nada —
  /// la UI debe indicarle al usuario que deseleccione uno primero.
  void toggleSeat(String seatCode) {
    if (_selectedSeats.contains(seatCode)) {
      _selectedSeats.remove(seatCode);
    } else if (_selectedSeats.length < requiredSeatCount) {
      _selectedSeats.add(seatCode);
    } else {
      return; // Ya no notifica: no hubo cambio real de estado.
    }
    notifyListeners();
  }

  void setBaggageOption(BaggageOption option) {
    _baggageOption = option;
    notifyListeners();
  }

  void setTravelInsurance(bool enabled) {
    _travelInsurance = enabled;
    notifyListeners();
  }

  void setPriorityBoarding(bool enabled) {
    _priorityBoarding = enabled;
    notifyListeners();
  }

  /// Confirma la reserva: valida que haya asientos suficientes y
  /// delega en [BookingRepository]. Los pasajeros y el pago llegan ya
  /// construidos desde [BookingScreen] (que los validó con su propio
  /// `Form`).
  Future<void> confirmBooking({
    required List<PassengerModel> passengers,
    required PaymentModel payment,
  }) async {
    if (!hasRequiredSeats) {
      _status = BookingStatus.error;
      _errorMessage = 'Selecciona $requiredSeatCount asiento(s) para continuar';
      notifyListeners();
      return;
    }

    _status = BookingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _reservation = await _repository.confirmBooking(
        flight: flight,
        fare: _selectedFare,
        seats: _selectedSeats,
        passengers: passengers,
        payment: payment,
        totalPrice: totalPrice,
      );
      _status = BookingStatus.success;
    } catch (_) {
      _status = BookingStatus.error;
      _errorMessage = 'No se pudo procesar el pago. Intenta de nuevo.';
    }
    notifyListeners();
  }
}
