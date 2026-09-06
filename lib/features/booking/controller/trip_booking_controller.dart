import 'package:flutter/foundation.dart';
import 'package:royal_airlines/features/booking/controller/booking_controller.dart'
    show BaggageOption, BaggageOptionInfo;
import 'package:royal_airlines/models/flight_model.dart';
import 'package:royal_airlines/models/seat_pricing.dart';

/// TripLegType
/// -----------
/// Identifica en qué tramo del viaje está el usuario cuando el tipo
/// de viaje es "Ida y vuelta". Para "Solo ida" no se usa — ese flujo
/// sigue pasando directo por [BookingScreen], sin tocar esta
/// arquitectura.
enum TripLegType { outbound, returnLeg }

/// LegBooking
/// ----------
/// Selección completa de UN tramo: vuelo, tarifa, asientos y equipaje
/// elegidos. Ida y Regreso tienen cada uno su propia instancia
/// independiente, con su propio cálculo de subtotal — nunca se
/// mezclan entre sí.
class LegBooking {
  LegBooking({
    required this.flight,
    required this.fare,
    required this.requiredSeatCount,
  });

  FlightModel flight;
  FareModel fare;
  final List<String> selectedSeats = [];
  BaggageOption baggageOption = BaggageOption.included;
  bool travelInsurance = false;
  bool priorityBoarding = false;
  final int requiredSeatCount;

  double get fareSubtotal => fare.price * requiredSeatCount;

  double get seatCharge => selectedSeats.fold<double>(
        0,
        (sum, code) => sum + SeatPricing.categoryForSeat(code).price,
      );

  double get travelExtrasPrice {
    var total = 0.0;
    if (travelInsurance) total += 25000;
    if (priorityBoarding) total += 18000;
    return total;
  }

  double get totalPrice =>
      fareSubtotal + seatCharge + baggageOption.price + travelExtrasPrice;

  bool get hasRequiredSeats => selectedSeats.length == requiredSeatCount;
}

/// TripBookingController
/// ----------------------
/// Coordina la reserva de un viaje "Ida y vuelta": mantiene DOS
/// [LegBooking] independientes y sabe en todo momento cuál tramo está
/// activo ([currentLeg]). Una única instancia se crea al elegir la
/// tarifa de ida (en [FlightsScreen]) y se pasa por constructor a
/// través de [LegBookingScreen] -> [FlightsScreen] (regreso) ->
/// [LegBookingScreen] (regreso) -> [CheckoutScreen]. No se registra
/// vía Provider porque su ciclo de vida atraviesa varias rutas del
/// Navigator que no comparten el mismo subárbol de widgets.
class TripBookingController extends ChangeNotifier {
  TripBookingController({
    required this.isRoundTrip,
    required this.requiredSeatCount,
  });

  final bool isRoundTrip;
  final int requiredSeatCount;

  LegBooking? outbound;
  LegBooking? returnLeg;
  TripLegType currentLeg = TripLegType.outbound;

  LegBooking? get currentLegBooking =>
      currentLeg == TripLegType.outbound ? outbound : returnLeg;

  void setOutboundSelection(FlightModel flight, FareModel fare) {
    outbound = LegBooking(
      flight: flight,
      fare: fare,
      requiredSeatCount: requiredSeatCount,
    );
    notifyListeners();
  }

  void setReturnSelection(FlightModel flight, FareModel fare) {
    returnLeg = LegBooking(
      flight: flight,
      fare: fare,
      requiredSeatCount: requiredSeatCount,
    );
    notifyListeners();
  }

  void setCurrentLeg(TripLegType leg) {
    currentLeg = leg;
    notifyListeners();
  }

  void changeFare(FareModel fare) {
    final leg = currentLegBooking;
    if (leg == null) return;
    leg.fare = fare;
    notifyListeners();
  }

  void toggleSeat(String seatCode) {
    final leg = currentLegBooking;
    if (leg == null) return;
    if (leg.selectedSeats.contains(seatCode)) {
      leg.selectedSeats.remove(seatCode);
    } else if (leg.selectedSeats.length < requiredSeatCount) {
      leg.selectedSeats.add(seatCode);
    } else {
      return;
    }
    notifyListeners();
  }

  void setBaggage(BaggageOption option) {
    final leg = currentLegBooking;
    if (leg == null) return;
    leg.baggageOption = option;
    notifyListeners();
  }

  void setTravelInsurance(bool enabled) {
    final leg = currentLegBooking;
    if (leg == null) return;
    leg.travelInsurance = enabled;
    notifyListeners();
  }

  void setPriorityBoarding(bool enabled) {
    final leg = currentLegBooking;
    if (leg == null) return;
    leg.priorityBoarding = enabled;
    notifyListeners();
  }

  double get grandTotal {
    double total = outbound?.totalPrice ?? 0;
    if (isRoundTrip) total += returnLeg?.totalPrice ?? 0;
    return total;
  }
}
