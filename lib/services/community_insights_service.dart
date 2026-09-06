import 'package:royal_airlines/core/network/api_client.dart';
import 'package:royal_airlines/core/network/api_contracts.dart';
import 'package:royal_airlines/models/traveler_profile_model.dart';

/// CommunityInsightsService
/// ------------------------
/// Llama a `GET /insights/community`, la única parte de "Tu Perfil de
/// Viajero" que depende de un backend real: comparar al usuario contra
/// el promedio de TODA la comunidad requiere datos agregados de todos
/// los usuarios, algo que Python calcula bajo demanda y Spring Boot
/// expone aquí — Flutter nunca llama a Python directamente.
class CommunityInsightsService {
  CommunityInsightsService({ApiClient? client})
      : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<CommunityInsights> fetchCommunityInsights() async {
    final response = await _client.get(ApiEndpoints.communityInsights);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return CommunityInsights.fromJson(data);
  }
}
