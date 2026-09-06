import 'package:flutter/foundation.dart';
import 'package:royal_airlines/features/reservations/repository/reservations_storage.dart';
import 'package:royal_airlines/models/reservation_model.dart';

/// ReservationsStore
/// -----------------
/// Estado GLOBAL de las reservas confirmadas por el usuario durante la
/// sesión (registrado en `app.dart`). [BookingScreen] escribe aquí al
/// confirmar una compra; [ReservationsScreen] y [ProfileScreen] leen
/// desde aquí para mostrar el historial y las estadísticas.
///
/// Persiste en disco vía [ReservationsStorage] (SharedPreferences como
/// JSON), asociado al `userId` de la cuenta activa: el historial
/// sobrevive a que la app se cierre por completo, se reinicie el
/// dispositivo, o el usuario cierre sesión y vuelva a entrar — NO es
/// solo un estado "Hot Reload" que se pierde apenas cambia algo. Solo
/// se descarta de memoria (nunca de disco) al cerrar sesión, para que
/// la próxima cuenta que use el dispositivo no vea reservas ajenas.
class ReservationsStore extends ChangeNotifier {
  ReservationsStore({ReservationsStorage? storage})
      : _storage = storage ?? ReservationsStorage();

  final ReservationsStorage _storage;
  List<ReservationModel> _reservations = [];
  String? _userId;
  bool _isLoading = false;

  /// Más recientes primero.
  List<ReservationModel> get reservations {
    final sorted = [..._reservations];
    sorted.sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
    return List.unmodifiable(sorted);
  }

  bool get isEmpty => _reservations.isEmpty;
  bool get isNotEmpty => _reservations.isNotEmpty;
  bool get isLoading => _isLoading;

  /// Carga el historial guardado en disco para [userId]. Se llama al
  /// iniciar sesión y al restaurar una sesión guardada (`tryRestoreSession`),
  /// para que el usuario recupere sus reservas de viajes anteriores en
  /// vez de empezar "desde cero" cada vez que abre la app.
  Future<void> loadForUser(String userId) async {
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    _reservations = await _storage.load(userId);

    _isLoading = false;
    notifyListeners();
  }

  void add(ReservationModel reservation) {
    _reservations.add(reservation);
    notifyListeners();
    _persist();
  }

  /// Se llama al cerrar sesión: limpia el estado EN MEMORIA para que la
  /// próxima cuenta que use el dispositivo no vea reservas ajenas, pero
  /// el historial en disco de este usuario se conserva intacto — al
  /// volver a iniciar sesión con esta misma cuenta, [loadForUser] lo
  /// recupera de nuevo.
  void clear() {
    _reservations = [];
    _userId = null;
    notifyListeners();
  }

  void _persist() {
    final userId = _userId;
    if (userId == null) return;
    _storage.save(userId, _reservations);
  }
}
