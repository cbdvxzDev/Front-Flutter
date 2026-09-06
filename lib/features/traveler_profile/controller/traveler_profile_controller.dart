import 'package:flutter/foundation.dart';
import 'package:royal_airlines/features/reservations/repository/reservations_store.dart';
import 'package:royal_airlines/features/traveler_profile/repository/traveler_profile_repository.dart';
import 'package:royal_airlines/models/traveler_profile_model.dart';

enum TravelerProfileStatus { idle, loading, success, error }

/// TravelerProfileController
/// -------------------------
/// El [archetype]/las métricas personales se calculan de forma
/// SÍNCRONA (no hay estado de carga para eso) porque
/// [TravelerProfileRepository.classify] solo lee memoria local. Solo
/// [fetchCommunityInsights] tiene estado async real, ya que sí depende
/// de una llamada de red (mock o real).
class TravelerProfileController extends ChangeNotifier {
  TravelerProfileController({
    required ReservationsStore reservationsStore,
    TravelerProfileRepository? repository,
  })  : _reservationsStore = reservationsStore,
        _repository = repository ?? TravelerProfileRepository() {
    _recomputeProfile();
    _reservationsStore.addListener(_recomputeProfile);
  }

  final ReservationsStore _reservationsStore;
  final TravelerProfileRepository _repository;

  TravelerProfileModel _profile = TravelerProfileModel.empty();
  TravelerProfileModel get profile => _profile;

  TravelerProfileStatus _communityStatus = TravelerProfileStatus.idle;
  TravelerProfileStatus get communityStatus => _communityStatus;

  CommunityInsights? _communityInsights;
  CommunityInsights? get communityInsights => _communityInsights;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoadingCommunity =>
      _communityStatus == TravelerProfileStatus.loading;

  void _recomputeProfile() {
    _profile = _repository.classify(_reservationsStore.reservations);
    notifyListeners();
  }

  Future<void> loadCommunityInsights() async {
    _communityStatus = TravelerProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _communityInsights = await _repository.fetchCommunityInsights();
      _communityStatus = TravelerProfileStatus.success;
    } catch (error) {
      _communityStatus = TravelerProfileStatus.error;
      _errorMessage = 'No se pudo cargar la comparación con la comunidad.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _reservationsStore.removeListener(_recomputeProfile);
    super.dispose();
  }
}
