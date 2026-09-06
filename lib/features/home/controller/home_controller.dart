import 'package:flutter/foundation.dart';
import 'package:royal_airlines/features/home/repository/home_repository.dart';
import 'package:royal_airlines/models/airport_model.dart';
import 'package:royal_airlines/models/travel_class.dart';

/// TripType
/// --------
/// Tipo de viaje seleccionado en el buscador.
enum TripType { roundTrip, oneWay }

/// PassengerCount
/// --------------
/// Conteo de pasajeros por categoría. Se modela como clase inmutable
/// (con `copyWith`) en vez de 3 enteros sueltos en el controller, para
/// que [PassengerSelector] pueda manipular una sola referencia y para
/// facilitar validaciones futuras (ej. "infantes no puede superar adultos").
class PassengerCount {
  final int adults;
  final int children;
  final int infants;

  const PassengerCount({
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
  });

  int get total => adults + children + infants;

  /// Texto resumen mostrado en el buscador, ej. "2 Adultos, 1 Niño".
  String get summary {
    final parts = <String>[];
    parts.add('$adults ${adults == 1 ? 'Adulto' : 'Adultos'}');
    if (children > 0) {
      parts.add('$children ${children == 1 ? 'Niño' : 'Niños'}');
    }
    if (infants > 0) {
      parts.add('$infants ${infants == 1 ? 'Infante' : 'Infantes'}');
    }
    return parts.join(', ');
  }

  PassengerCount copyWith({int? adults, int? children, int? infants}) {
    return PassengerCount(
      adults: adults ?? this.adults,
      children: children ?? this.children,
      infants: infants ?? this.infants,
    );
  }
}

/// HomeController
/// --------------
/// Gestor de estado (Provider/ChangeNotifier) de la pantalla Home:
///   - Estado del formulario de búsqueda (tipo de viaje, origen/destino,
///     fechas, pasajeros, clase).
///   - Datos cargados desde [HomeRepository] (aeropuertos, promociones,
///     destinos populares).
///
/// La UI (HomeScreen y sus widgets) solo lee estas propiedades y llama
/// a estos métodos; nunca accede a [HomeRepository] directamente.
class HomeController extends ChangeNotifier {
  HomeController({HomeRepository? repository})
      : _repository = repository ?? HomeRepository();

  final HomeRepository _repository;

  // --- Estado del formulario de búsqueda ---
  TripType _tripType = TripType.roundTrip;
  AirportModel? _origin;
  AirportModel? _destination;
  DateTime? _departureDate;
  DateTime? _returnDate;
  PassengerCount _passengers = const PassengerCount();
  TravelClass _travelClass = TravelClass.economy;

  // --- Datos cargados ---
  List<AirportModel> _airports = [];
  List<PromotionModel> _promotions = [];
  List<AirportModel> _popularDestinations = [];
  bool _isLoading = false;

  TripType get tripType => _tripType;
  AirportModel? get origin => _origin;
  AirportModel? get destination => _destination;
  DateTime? get departureDate => _departureDate;
  DateTime? get returnDate => _returnDate;
  PassengerCount get passengers => _passengers;
  TravelClass get travelClass => _travelClass;

  List<AirportModel> get airports => _airports;
  List<PromotionModel> get promotions => _promotions;
  List<AirportModel> get popularDestinations => _popularDestinations;
  bool get isLoading => _isLoading;

  /// Carga inicial de datos mock. Se llama una sola vez al crear el
  /// controller (ver [HomeScreen]).
  Future<void> loadHomeData() async {
    _isLoading = true;
    notifyListeners();

    final results = await Future.wait([
      _repository.getAirports(),
      _repository.getPromotions(),
      _repository.getPopularDestinations(),
    ]);

    _airports = results[0] as List<AirportModel>;
    _promotions = results[1] as List<PromotionModel>;
    _popularDestinations = results[2] as List<AirportModel>;

    // Origen/destino iniciales sugeridos, si hay suficientes aeropuertos.
    if (_airports.length >= 2) {
      _origin = _airports[0];
      _destination = _airports[1];
    }

    _isLoading = false;
    notifyListeners();
  }

  void setTripType(TripType type) {
    _tripType = type;
    // Un vuelo solo de ida no necesita fecha de regreso.
    if (type == TripType.oneWay) _returnDate = null;
    notifyListeners();
  }

  void setOrigin(AirportModel airport) {
    _origin = airport;
    notifyListeners();
  }

  void setDestination(AirportModel airport) {
    _destination = airport;
    notifyListeners();
  }

  /// Intercambia origen y destino (botón de swap en el buscador).
  void swapAirports() {
    final temp = _origin;
    _origin = _destination;
    _destination = temp;
    notifyListeners();
  }

  void setDepartureDate(DateTime date) {
    _departureDate = date;
    // Si la fecha de regreso quedó antes de la nueva salida, se limpia.
    if (_returnDate != null && _returnDate!.isBefore(date)) {
      _returnDate = null;
    }
    notifyListeners();
  }

  void setReturnDate(DateTime date) {
    _returnDate = date;
    notifyListeners();
  }

  void updatePassengers(PassengerCount count) {
    _passengers = count;
    notifyListeners();
  }

  void setTravelClass(TravelClass travelClass) {
    _travelClass = travelClass;
    notifyListeners();
  }
}
