/// TravelerArchetype
/// ------------------
/// Perfil de viajero asignado por el clasificador de minería de datos
/// (ver [TravelerProfileModel.classify]). Cada arquetipo representa un
/// "centroide" de comportamiento de viaje, no un vuelo específico —a
/// diferencia de [FlightDemandForecast]/[PriceForecast], que evalúan un
/// solo vuelo, esto resume TODO el historial del usuario en una sola
/// etiqueta, como el "Wrapped" anual de una app de música.
enum TravelerArchetype {
  newcomer,
  dealHunter,
  explorer,
  frequentFlyer,
  premiumTraveler,
}

extension TravelerArchetypeInfo on TravelerArchetype {
  String get emoji {
    switch (this) {
      case TravelerArchetype.newcomer:
        return '🌱';
      case TravelerArchetype.dealHunter:
        return '🎯';
      case TravelerArchetype.explorer:
        return '🌎';
      case TravelerArchetype.frequentFlyer:
        return '✈️';
      case TravelerArchetype.premiumTraveler:
        return '👑';
    }
  }

  String get label {
    switch (this) {
      case TravelerArchetype.newcomer:
        return 'Nuevo en vuelo';
      case TravelerArchetype.dealHunter:
        return 'Cazador de ofertas';
      case TravelerArchetype.explorer:
        return 'Explorador';
      case TravelerArchetype.frequentFlyer:
        return 'Viajero frecuente';
      case TravelerArchetype.premiumTraveler:
        return 'Viajero premium';
    }
  }

  String get description {
    switch (this) {
      case TravelerArchetype.newcomer:
        return 'Aún no tienes reservas registradas. En cuanto reserves tu '
            'primer vuelo, empezamos a armar tu perfil.';
      case TravelerArchetype.dealHunter:
        return 'La mayoría de tus reservas fueron la tarifa más económica '
            'disponible. Sabes encontrar el mejor precio.';
      case TravelerArchetype.explorer:
        return 'Has volado a varios destinos distintos. Te gusta conocer '
            'lugares nuevos más que repetir siempre la misma ruta.';
      case TravelerArchetype.frequentFlyer:
        return 'Reservas con frecuencia. El aire ya casi es tu segunda casa.';
      case TravelerArchetype.premiumTraveler:
        return 'Sueles elegir tarifas premium. Viajas priorizando comodidad '
            'sobre precio.';
    }
  }
}

/// TravelerProfileModel
/// ---------------------
/// Resultado del análisis de minería de datos sobre el historial de
/// reservas del propio usuario. Combina dos fuentes intencionalmente
/// distintas:
///
/// - Las métricas personales ([totalTrips], [uniqueDestinations], etc.)
///   y el [archetype] se calculan LOCALMENTE a partir de
///   [ReservationsStore] con [TravelerProfileModel.classify]: es rápido,
///   no depende de red y siempre está disponible aunque el backend esté
///   caído.
/// - [CommunityInsights] SÍ requiere backend real: comparar a un
///   usuario contra el promedio de TODOS los usuarios es información
///   agregada que Python calcula sobre la base de datos completa, algo
///   que Flutter no puede ni debe intentar replicar localmente.
class TravelerProfileModel {
  final TravelerArchetype archetype;
  final int totalTrips;
  final int uniqueDestinations;
  final double totalSpent;
  final double averageTicketPrice;

  /// Fracción (0.0 a 1.0) de reservas donde se eligió la tarifa más
  /// económica disponible para ese vuelo.
  final double cheapestFareRatio;

  /// Fracción (0.0 a 1.0) de reservas en clase Business o Primera.
  final double premiumRatio;

  final String? mostVisitedCity;

  const TravelerProfileModel({
    required this.archetype,
    required this.totalTrips,
    required this.uniqueDestinations,
    required this.totalSpent,
    required this.averageTicketPrice,
    required this.cheapestFareRatio,
    required this.premiumRatio,
    this.mostVisitedCity,
  });

  factory TravelerProfileModel.empty() => const TravelerProfileModel(
        archetype: TravelerArchetype.newcomer,
        totalTrips: 0,
        uniqueDestinations: 0,
        totalSpent: 0,
        averageTicketPrice: 0,
        cheapestFareRatio: 0,
        premiumRatio: 0,
      );
}

/// CommunityInsights
/// -----------------
/// Comparación del usuario contra el resto de la comunidad de Royal
/// Airlines. Es el único dato de este módulo que viene (o vendrá) de
/// una llamada REST real, porque calcular un promedio global de TODOS
/// los usuarios requiere la base de datos completa, no solo el
/// historial de una sola cuenta.
class CommunityInsights {
  /// Promedio de reservas por usuario en toda la aerolínea.
  final double averageTripsPerUser;

  /// Percentil del usuario actual frente a la comunidad (0.0 a 1.0).
  /// Ej. 0.85 significa "reservas más que el 85% de los usuarios".
  final double tripsPercentile;

  final String trendingDestinationCity;

  const CommunityInsights({
    required this.averageTripsPerUser,
    required this.tripsPercentile,
    required this.trendingDestinationCity,
  });

  factory CommunityInsights.fromJson(Map<String, dynamic> json) {
    return CommunityInsights(
      averageTripsPerUser:
          (json['averageTripsPerUser'] as num?)?.toDouble() ?? 0,
      tripsPercentile: (json['tripsPercentile'] as num?)?.toDouble() ?? 0,
      trendingDestinationCity:
          json['trendingDestinationCity'] as String? ?? '—',
    );
  }
}
