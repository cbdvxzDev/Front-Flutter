/// ApiEndpoints
/// ------------
/// Contratos HTTP mínimos para una app de vuelos escolar. Los nombres
/// están pensados para que el backend pueda implementarlos sin más dudas.
class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/me';
  static const String changePassword = '/auth/change-password';
  static const String airports = '/airports';
  static const String promotions = '/promotions';
  static const String destinations = '/destinations';
  static const String flightsSearch = '/flights/search';
  static const String flightDetail = '/flights/{flightId}';
  static const String bookings = '/bookings';
  static const String payments = '/payments/confirm';
  static const String reservations = '/reservations';
  static const String reservationDetail = '/reservations/{reservationId}';

  /// Comparación agregada del usuario actual frente al resto de la
  /// comunidad de Royal Airlines (promedio de reservas, percentil,
  /// destino en tendencia). Se calcula sobre TODA la base de datos, por
  /// eso es la única parte de "Tu Perfil de Viajero" que sí necesita
  /// backend real — no se puede calcular localmente con el historial
  /// de un solo usuario.
  static const String communityInsights = '/insights/community';
}

/// ApiContractNotes
/// ----------------
/// Esta clase no reemplaza la documentación del backend, pero sí deja
/// un recordatorio claro de los payloads y respuestas esperados.
class ApiContractNotes {
  ApiContractNotes._();

  static const Map<String, Object> loginRequest = {
    'email': 'demo@royalairlines.com',
    'password': 'Demo2026!',
  };

  static const Map<String, Object> loginResponse = {
    'token': 'jwt_token_example',
    'user': {
      'id': 'user-id',
      'fullName': 'Nombre del usuario',
      'email': 'demo@royalairlines.com',
    },
  };

  static const Map<String, Object> flightSearchRequest = {
    'origin': 'BOG',
    'destination': 'MEX',
    'departureDate': '2026-09-01',
    'returnDate': '2026-09-05',
    'passengers': 2,
  };

  static const Map<String, Object> bookingRequest = {
    'flightId': 'FL_1001',
    'passengers': [
      {
        'fullName': 'Nombre del pasajero',
        'documentNumber': '12345678',
        'birthDate': '1995-06-15',
      },
    ],
    'fareType': 'economy',
    'seats': ['12A', '12B'],
  };

  static const Map<String, Object> paymentRequest = {
    'bookingId': 'BK_1001',
    'paymentMethod': 'card',
    'cardHolderName': 'Titular de la tarjeta',
    'cardLastFour': '4242',
    'expiry': '12/29',
    'amount': 520000,
    'currency': 'COP',
  };

  static const Map<String, Object> successResponse = {
    'success': true,
    'message': 'Operation completed',
    'data': <String, Object>{},
  };
}
