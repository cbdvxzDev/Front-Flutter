import 'package:royal_airlines/core/utils/seat_occupancy.dart';
import 'package:royal_airlines/models/airport_model.dart';
import 'package:royal_airlines/models/travel_class.dart';

/// FlightDemandForecast
/// --------------------
/// Estimación de qué tan probable es que este vuelo se llene, calculada
/// a partir de los asientos disponibles restantes frente a la
/// capacidad típica de la aeronave. Es la pieza "predictiva" (Minería
/// de datos 2) integrada directamente en el flujo de búsqueda/reserva,
/// no solo en una pantalla de estadísticas separada.
///
/// Hoy se calcula con una fórmula simple en el propio modelo (ver
/// [FlightModel.demandForecast]); cuando Python entregue su propio
/// score de probabilidad, este valor se puede reemplazar por el que
/// venga del backend sin cambiar la UI que lo consume.
class FlightDemandForecast {
  final double fillProbability; // 0.0 a 1.0
  final String level; // 'Alta', 'Media', 'Baja'

  const FlightDemandForecast({
    required this.fillProbability,
    required this.level,
  });

  bool get isUrgent => level == 'Alta';
}

/// PriceForecast
/// -------------
/// Estimación simple de hacia dónde podría moverse el precio de este
/// vuelo en los próximos días, calculada a partir de qué tan ocupado
/// está (a mayor ocupación, mayor probabilidad de que suba de precio).
/// Es el mismo tipo de placeholder que [FlightDemandForecast]: hoy es
/// una fórmula transparente en el modelo, mañana puede venir de un
/// modelo real de Python sin cambiar la UI.
class PriceForecast {
  final bool isRising; // true = sugiere comprar ya, false = puede esperar
  final int changePercent; // variación estimada en los próximos días

  const PriceForecast({
    required this.isRising,
    required this.changePercent,
  });
}

/// FareModel
/// ---------
/// Representa una tarifa disponible para un vuelo específico. Cada
/// tarifa incluye su lista de [benefits] (equipaje, cambios,
/// devoluciones, acumulación de puntos, etc.) para mostrarse en el
/// bottom sheet de selección, estilo aerolínea real.
///
/// [seatsAvailable] siempre es mayor a 0 en este mock: nunca se
/// muestran tarifas agotadas, ya que no aporta valor de UX mostrar
/// una opción que el usuario no puede elegir.
class FareModel {
  final TravelClass travelClass;
  final String tierName; // "Basic", "Light", "Full", "Premium Economy"
  final double price;
  final int seatsAvailable;
  final List<String> benefits;

  const FareModel({
    required this.travelClass,
    required this.tierName,
    required this.price,
    required this.seatsAvailable,
    required this.benefits,
  });

  bool get isAlmostSoldOut => seatsAvailable <= 3;

  factory FareModel.fromJson(Map<String, dynamic> json) {
    return FareModel(
      travelClass: travelClassFromStorageKey(json['travelClass'] as String),
      tierName: json['tierName'] as String,
      price: (json['price'] as num).toDouble(),
      seatsAvailable: json['seatsAvailable'] as int,
      benefits: (json['benefits'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'travelClass': travelClass.storageKey,
      'tierName': tierName,
      'price': price,
      'seatsAvailable': seatsAvailable,
      'benefits': benefits,
    };
  }
}

/// FlightModel
/// -----------
/// Representa un vuelo ofrecido en los resultados de búsqueda.
class FlightModel {
  final String id;
  final String airline;
  final String flightNumber;
  final String aircraft;
  final AirportModel origin;
  final AirportModel destination;
  final DateTime departureTime;
  final DateTime arrivalTime;

  /// Número de escalas. 0 = vuelo directo.
  final int stops;

  final List<FareModel> fares;

  const FlightModel({
    required this.id,
    required this.airline,
    required this.flightNumber,
    required this.aircraft,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.stops,
    required this.fares,
  });

  Duration get duration => arrivalTime.difference(departureTime);

  bool get isDirect => stops == 0;

  String get stopsLabel {
    if (stops == 0) return 'Directo';
    return '$stops ${stops == 1 ? 'parada' : 'paradas'}';
  }

  /// Tarifa más económica disponible, usada para mostrar "desde $X".
  FareModel get cheapestFare =>
      fares.reduce((a, b) => a.price < b.price ? a : b);

  FareModel? fareFor(TravelClass travelClass) {
    for (final fare in fares) {
      if (fare.travelClass == travelClass) return fare;
    }
    return null;
  }

  /// Predicción de qué tan probable es que este vuelo se llene.
  ///
  /// Usa [SeatOccupancy], la MISMA lógica determinística (basada en
  /// [id]) que [SeatSelector] usa para pintar los asientos ocupados en
  /// el mapa, así el porcentaje que se ve en la tarjeta de resultados
  /// coincide exactamente con la ocupación real del mapa de asientos
  /// de ese vuelo. Es un placeholder transparente del score que
  /// Python calcularía a futuro; se puede reemplazar por el valor real
  /// del backend sin cambiar la UI que lo consume.
  FlightDemandForecast get demandForecast {
    final fillProbability =
        SeatOccupancy.occupancyRatioFor(id).clamp(0.0, 0.97);

    final level = fillProbability >= 0.75
        ? 'Alta'
        : fillProbability >= 0.5
            ? 'Media'
            : 'Baja';

    return FlightDemandForecast(
      fillProbability: fillProbability,
      level: level,
    );
  }

  /// Predicción de tendencia de precio para los próximos días.
  ///
  /// Fórmula simple e intencionalmente transparente: entre más
  /// ocupado esté el vuelo, más probable (y más fuerte) es la subida
  /// de precio estimada. Reutiliza [demandForecast] para no introducir
  /// una fuente de aleatoriedad distinta.
  PriceForecast get priceForecast {
    final fill = demandForecast.fillProbability;
    final isRising = fill >= 0.55;
    // Variación estimada entre 4% y 22%, proporcional a la ocupación.
    final changePercent = (fill * 25).round().clamp(4, 22);
    return PriceForecast(
      isRising: isRising,
      changePercent: isRising ? changePercent : (changePercent / 2).round(),
    );
  }

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    return FlightModel(
      id: json['id'] as String,
      airline: json['airline'] as String,
      flightNumber: json['flightNumber'] as String,
      aircraft: json['aircraft'] as String,
      origin: AirportModel.fromJson(json['origin'] as Map<String, dynamic>),
      destination:
          AirportModel.fromJson(json['destination'] as Map<String, dynamic>),
      departureTime: DateTime.parse(json['departureTime'] as String),
      arrivalTime: DateTime.parse(json['arrivalTime'] as String),
      stops: json['stops'] as int,
      fares: (json['fares'] as List)
          .map((f) => FareModel.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'airline': airline,
      'flightNumber': flightNumber,
      'aircraft': aircraft,
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'departureTime': departureTime.toIso8601String(),
      'arrivalTime': arrivalTime.toIso8601String(),
      'stops': stops,
      'fares': fares.map((f) => f.toJson()).toList(),
    };
  }
}
