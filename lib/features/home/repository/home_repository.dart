import 'package:royal_airlines/models/airport_model.dart';
import 'package:royal_airlines/core/config/app_config.dart';
import 'package:royal_airlines/core/network/api_client.dart';
import 'package:royal_airlines/core/network/api_contracts.dart';

/// PromotionModel
/// --------------
/// Representa una promoción/banner mostrado en el slider de Home.
class PromotionModel {
  final String title;
  final String subtitle;
  final String discountLabel;

  const PromotionModel({
    required this.title,
    required this.subtitle,
    required this.discountLabel,
  });
}

/// HomeRepository
/// --------------
/// Única responsable de proveer los datos que consume Home: lista de
/// aeropuertos disponibles, promociones activas y destinos populares.
/// Hoy es MOCK LOCAL; el día que exista un backend real, solo este
/// archivo cambia.
class HomeRepository {
  HomeRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AirportModel>> getAirports() async {
    if (!AppConfig.useMockApi) {
      final response = await _apiClient.get(ApiEndpoints.airports);
      return _airportList(response['data']);
    }

    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      AirportModel(
        code: 'BOG',
        city: 'Bogotá',
        country: 'Colombia',
        airportName: 'El Dorado',
      ),
      AirportModel(
        code: 'MDE',
        city: 'Medellín',
        country: 'Colombia',
        airportName: 'José María Córdova',
      ),
      AirportModel(
        code: 'CTG',
        city: 'Cartagena',
        country: 'Colombia',
        airportName: 'Rafael Núñez',
      ),
      AirportModel(
        code: 'CLO',
        city: 'Cali',
        country: 'Colombia',
        airportName: 'Alfonso Bonilla Aragón',
      ),
      AirportModel(
        code: 'MIA',
        city: 'Miami',
        country: 'Estados Unidos',
        airportName: 'Miami International',
      ),
      AirportModel(
        code: 'MAD',
        city: 'Madrid',
        country: 'España',
        airportName: 'Adolfo Suárez',
      ),
      AirportModel(
        code: 'DOH',
        city: 'Doha',
        country: 'Qatar',
        airportName: 'Hamad International',
      ),
    ];
  }

  /// Promociones activas para el slider de Home. Mezcla rutas
  /// internacionales, nacionales, temporada (puentes festivos) y
  /// beneficios de fidelización, para que el slider se sienta variado
  /// en vez de repetir siempre "vuelos internacionales".
  Future<List<PromotionModel>> getPromotions() async {
    if (!AppConfig.useMockApi) {
      final response = await _apiClient.get(ApiEndpoints.promotions);
      final data = response['data'];
      if (data is! List) return const <PromotionModel>[];
      return data
          .whereType<Map<String, dynamic>>()
          .map((item) => PromotionModel(
                title: item['title'] as String? ?? 'Promoción',
                subtitle: item['subtitle'] as String? ?? '',
                discountLabel: item['discountLabel'] as String? ?? '',
              ))
          .toList();
    }

    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      PromotionModel(
        title: 'Cartagena desde',
        subtitle: 'Fin de semana ideal con tarifas especiales',
        discountLabel: 'Desde COP 245K',
      ),
      PromotionModel(
        title: 'Vuelos nacionales',
        subtitle: 'Conecta Bogotá, Medellín, Cali y más',
        discountLabel: 'Hasta 30% OFF',
      ),
      PromotionModel(
        title: 'Upgrade Premium',
        subtitle: 'Más espacio, más confort y mejor experiencia',
        discountLabel: 'A solo COP 89K',
      ),
      PromotionModel(
        title: 'Madrid en oferta',
        subtitle: 'Destinos internacionales para viajar ya',
        discountLabel: 'Hasta 25% OFF',
      ),
      PromotionModel(
        title: 'Royal Club',
        subtitle: 'Acumula millas y disfruta beneficios exclusivos',
        discountLabel: '2X Millas',
      ),
      PromotionModel(
        title: 'Escapada al Caribe',
        subtitle: 'Sol, playa y vuelos directos desde Colombia',
        discountLabel: 'Bajo reserva',
      ),
    ];
  }

  /// Destinos populares destacados en Home.
  Future<List<AirportModel>> getPopularDestinations() async {
    if (!AppConfig.useMockApi) {
      final response = await _apiClient.get(ApiEndpoints.destinations);
      return _airportList(response['data']);
    }

    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      AirportModel(
        code: 'MAD',
        city: 'Madrid',
        country: 'España',
        airportName: 'Adolfo Suárez',
      ),
      AirportModel(
        code: 'DOH',
        city: 'Doha',
        country: 'Qatar',
        airportName: 'Hamad International',
      ),
      AirportModel(
        code: 'MIA',
        city: 'Miami',
        country: 'Estados Unidos',
        airportName: 'Miami International',
      ),
      AirportModel(
        code: 'CTG',
        city: 'Cartagena',
        country: 'Colombia',
        airportName: 'Rafael Núñez',
      ),
      AirportModel(
        code: 'CLO',
        city: 'Cali',
        country: 'Colombia',
        airportName: 'Alfonso Bonilla Aragón',
      ),
    ];
  }

  List<AirportModel> _airportList(Object? data) {
    if (data is! List) return const <AirportModel>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(AirportModel.fromJson)
        .toList();
  }
}
