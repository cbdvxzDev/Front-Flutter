import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_airlines/core/animations/app_motion.dart';
import 'package:royal_airlines/core/theme/app_colors.dart';
import 'package:royal_airlines/core/theme/app_spacing.dart';
import 'package:royal_airlines/core/theme/app_theme.dart';
import 'package:royal_airlines/core/utils/currency_formatter.dart';
import 'package:royal_airlines/features/reservations/repository/reservations_store.dart';
import 'package:royal_airlines/features/traveler_profile/controller/traveler_profile_controller.dart';
import 'package:royal_airlines/features/traveler_profile/widgets/animated_stat_tile.dart';
import 'package:royal_airlines/features/traveler_profile/widgets/archetype_badge.dart';
import 'package:royal_airlines/features/traveler_profile/widgets/community_comparison_card.dart';
import 'package:royal_airlines/models/traveler_profile_model.dart';
import 'package:royal_airlines/shared/widgets/custom_button.dart';
import 'package:royal_airlines/shared/widgets/fade_slide_in.dart';
import 'package:royal_airlines/shared/widgets/section_title.dart';

/// TravelerProfileScreen
/// -----------------------
/// Tab "Para ti" del navbar principal. A diferencia de los badges
/// predictivos por-vuelo que ya existen en `features/flights/`
/// (ocupación, tendencia de precio), esta pantalla es minería de datos
/// AGREGADA sobre todo el historial del usuario: lo clasifica en un
/// [TravelerArchetype] (clustering nearest-centroid, ver
/// `TravelerProfileRepository.classify`) y lo compara contra el resto
/// de la comunidad (`GET /insights/community`, dato agregado real).
///
/// Es visible para cualquier cuenta autenticada, sin distinción de
/// roles: cada usuario ve su propio perfil, calculado sobre sus
/// propias reservas.
class TravelerProfileScreen extends StatelessWidget {
  const TravelerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TravelerProfileController(
        reservationsStore: context.read<ReservationsStore>(),
      )..loadCommunityInsights(),
      child: const _TravelerProfileBody(),
    );
  }
}

class _TravelerProfileBody extends StatelessWidget {
  const _TravelerProfileBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TravelerProfileController>();
    final profile = controller.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFF4FA),
              AppColors.background,
              AppColors.background
            ],
            stops: [0, 0.24, 1],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.loadCommunityInsights,
            child: Stack(
              children: [
                const Positioned(
                  top: -72,
                  right: -24,
                  child: _AmbientGlow(size: 170, color: AppColors.gold),
                ),
                const Positioned(
                  top: 112,
                  left: -40,
                  child: _AmbientGlow(size: 150, color: AppColors.primaryLight),
                ),
                Positioned.fill(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.lg,
                      AppSpacing.screenPadding,
                      40,
                    ),
                    children: [
                      FadeSlideIn(
                        index: 0,
                        child: _Header(
                          profile: profile,
                          communityStatus: controller.communityStatus,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const FadeSlideIn(
                        index: 1,
                        child: SectionTitle(title: 'Tu esencia viajera'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FadeSlideIn(
                        index: 2,
                        child: ArchetypeBadge(archetype: profile.archetype),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (profile.totalTrips == 0)
                        const FadeSlideIn(index: 3, child: _NoTripsHint())
                      else ...[
                        FadeSlideIn(
                          index: 3,
                          child: _ProfileHighlights(profile: profile),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        const FadeSlideIn(
                          index: 4,
                          child: SectionTitle(title: 'Tu dashboard personal'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _StatsGrid(profile: profile, startIndex: 5),
                        const SizedBox(height: AppSpacing.xxl),
                        const FadeSlideIn(
                          index: 9,
                          child: SectionTitle(
                              title: 'Comparación con la comunidad'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FadeSlideIn(
                          index: 10,
                          child: _CommunitySection(
                            controller: controller,
                            userTrips: profile.totalTrips,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final TravelerProfileModel profile;
  final TravelerProfileStatus communityStatus;

  const _Header({
    required this.profile,
    required this.communityStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: AppColors.glassGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: AppShadows.card,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: AppColors.goldLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu Perfil de Viajero',
                      style: theme.headlineMedium?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ) ??
                          const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Un dashboard premium con tu arquetipo, tus hábitos y la huella que dejas al volar.',
                      style: theme.bodyMedium?.copyWith(height: 1.45) ??
                          const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeaderPill(
                icon: Icons.auto_graph_rounded,
                label: profile.totalTrips > 0
                    ? 'Construido con tu historial'
                    : 'Listo para tu primer vuelo',
              ),
              _HeaderPill(
                icon: _communityStatusIcon(communityStatus),
                label: _communityStatusLabel(communityStatus),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ) ??
                const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHighlights extends StatelessWidget {
  final TravelerProfileModel profile;

  const _ProfileHighlights({required this.profile});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (AppSpacing.md * 2)) / 3;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: itemWidth,
              child: _HighlightCard(
                icon: Icons.location_on_rounded,
                value: profile.mostVisitedCity ?? 'Por descubrir',
                label: 'Destino frecuente',
                iconColor: AppColors.info,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _HighlightCard(
                icon: Icons.local_offer_rounded,
                value: '${(profile.cheapestFareRatio * 100).round()}%',
                label: 'Reservas smart',
                iconColor: AppColors.success,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _HighlightCard(
                icon: Icons.workspace_premium_rounded,
                value: '${(profile.premiumRatio * 100).round()}%',
                label: 'Elecciones premium',
                iconColor: AppColors.gold,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _HighlightCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ) ??
                const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ) ??
                const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final TravelerProfileModel profile;
  final int startIndex;

  const _StatsGrid({required this.profile, required this.startIndex});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatDescriptor(
        label: 'Viajes reservados',
        value: '${profile.totalTrips}',
        icon: Icons.confirmation_number_rounded,
      ),
      _StatDescriptor(
        label: 'Destinos distintos',
        value: '${profile.uniqueDestinations}',
        icon: Icons.public_rounded,
      ),
      _StatDescriptor(
        label: 'Total invertido',
        value: CurrencyFormatter.cop(profile.totalSpent),
        icon: Icons.account_balance_wallet_rounded,
      ),
      _StatDescriptor(
        label: 'Tiquete promedio',
        value: CurrencyFormatter.cop(profile.averageTicketPrice),
        icon: Icons.trending_up_rounded,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        mainAxisExtent: 168,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return FadeSlideIn(
          index: startIndex + index,
          child: AnimatedStatTile(
            label: stat.label,
            value: stat.value,
            icon: stat.icon,
            delay: AppMotion.staggerDelay(index + 1),
          ),
        );
      },
    );
  }
}

class _StatDescriptor {
  final String label;
  final String value;
  final IconData icon;

  const _StatDescriptor({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _NoTripsHint extends StatelessWidget {
  const _NoTripsHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: AppColors.glassGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppShadows.card,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.explore_rounded,
              color: AppColors.goldLight,
              size: 34,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Tu dashboard despega con tu primer viaje',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ) ??
                const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Reserva tu primer vuelo y aquí aparecerán tu arquetipo, tus hábitos de reserva y tu lugar dentro de la comunidad Royal Airlines.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.45) ??
                const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _CommunitySection extends StatelessWidget {
  final TravelerProfileController controller;
  final int userTrips;

  const _CommunitySection({
    required this.controller,
    required this.userTrips,
  });

  @override
  Widget build(BuildContext context) {
    switch (controller.communityStatus) {
      case TravelerProfileStatus.loading:
      case TravelerProfileStatus.idle:
        return const _CommunityLoading();
      case TravelerProfileStatus.error:
        return _CommunityError(
          message: controller.errorMessage ?? 'Ocurrió un error.',
          onRetry: controller.loadCommunityInsights,
        );
      case TravelerProfileStatus.success:
        final insights = controller.communityInsights;
        if (insights == null) return const SizedBox.shrink();
        return CommunityComparisonCard(
          insights: insights,
          userTrips: userTrips,
        );
    }
  }
}

class _CommunityLoading extends StatelessWidget {
  const _CommunityLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: AppColors.glassGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Comparando tu ritmo con la comunidad…',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ) ??
                      const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Estamos alineando tus datos con el promedio global de Royal Airlines.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4) ??
                    const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SkeletonBar(widthFactor: 0.88, height: 12),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            children: [
              Expanded(child: _SkeletonTile()),
              SizedBox(width: AppSpacing.md),
              Expanded(child: _SkeletonTile()),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double widthFactor;
  final double height;

  const _SkeletonBar({required this.widthFactor, required this.height});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.skeletonBase,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBar(widthFactor: 0.45, height: 10),
          SizedBox(height: AppSpacing.md),
          _SkeletonBar(widthFactor: 0.7, height: 18),
          SizedBox(height: AppSpacing.sm),
          _SkeletonBar(widthFactor: 0.55, height: 10),
        ],
      ),
    );
  }
}

class _CommunityError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CommunityError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: AppColors.glassGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.error,
              size: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No pudimos traer la comparación comunitaria',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ) ??
                const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4) ??
                    const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: CustomButton.secondary(
              label: 'Reintentar',
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.08),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 56,
              spreadRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}

String _communityStatusLabel(TravelerProfileStatus status) {
  switch (status) {
    case TravelerProfileStatus.loading:
      return 'Sincronizando comunidad';
    case TravelerProfileStatus.idle:
      return 'Comunidad por cargar';
    case TravelerProfileStatus.success:
      return 'Benchmark listo';
    case TravelerProfileStatus.error:
      return 'Benchmark no disponible';
  }
}

IconData _communityStatusIcon(TravelerProfileStatus status) {
  switch (status) {
    case TravelerProfileStatus.loading:
      return Icons.sync_rounded;
    case TravelerProfileStatus.idle:
      return Icons.schedule_rounded;
    case TravelerProfileStatus.success:
      return Icons.verified_rounded;
    case TravelerProfileStatus.error:
      return Icons.error_outline_rounded;
  }
}
