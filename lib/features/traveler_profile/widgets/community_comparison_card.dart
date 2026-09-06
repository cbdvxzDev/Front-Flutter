import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:royal_airlines/core/animations/app_motion.dart';
import 'package:royal_airlines/core/theme/app_colors.dart';
import 'package:royal_airlines/core/theme/app_spacing.dart';
import 'package:royal_airlines/core/theme/app_theme.dart';
import 'package:royal_airlines/models/traveler_profile_model.dart';

/// CommunityComparisonCard
/// ------------------------
/// Visualización premium del ritmo de viaje del usuario frente a la
/// comunidad de Royal Airlines.
class CommunityComparisonCard extends StatelessWidget {
  final CommunityInsights insights;
  final int userTrips;

  const CommunityComparisonCard({
    super.key,
    required this.insights,
    required this.userTrips,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final percentile = insights.tripsPercentile.clamp(0.0, 1.0).toDouble();
    final percentileLabel = (percentile * 100).round();
    final communityAverage =
        insights.averageTripsPerUser < 0 ? 0.0 : insights.averageTripsPerUser;
    final maxTrips =
        math.max(1.0, math.max(userTrips.toDouble(), communityAverage));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.groups_rounded,
                  color: AppColors.goldLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Frente a la comunidad',
                  style: theme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: AppShadows.goldGlow,
                ),
                child: Text(
                  'Top $percentileLabel%',
                  style: theme.bodyMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ) ??
                      const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Viajas más que el $percentileLabel% de los usuarios de Royal Airlines.',
            style: theme.headlineMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ) ??
                const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Esta lectura compara tu historial con el comportamiento promedio de toda la comunidad.',
            style: theme.bodyMedium?.copyWith(height: 1.45) ??
                const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _PercentileTrack(percentile: percentile),
          const SizedBox(height: AppSpacing.xl),
          _ComparisonMetricBar(
            label: 'Tus viajes',
            valueLabel: '$userTrips',
            ratio: userTrips / maxTrips,
            icon: Icons.person_rounded,
            gradient: AppColors.goldGradient,
          ),
          const SizedBox(height: AppSpacing.md),
          _ComparisonMetricBar(
            label: 'Promedio comunidad',
            valueLabel: communityAverage.toStringAsFixed(1),
            ratio: communityAverage / maxTrips,
            icon: Icons.public_rounded,
            gradient: AppColors.primaryGradient,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _InsightTile(
                  icon: Icons.flight_takeoff_rounded,
                  title: 'Promedio global',
                  value:
                      '${communityAverage.toStringAsFixed(1)} viajes por usuario',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _InsightTile(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Destino tendencia',
                  value: insights.trendingDestinationCity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PercentileTrack extends StatelessWidget {
  final double percentile;

  const _PercentileTrack({required this.percentile});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: percentile),
          duration: AppMotion.slow,
          curve: AppMotion.standard,
          builder: (context, animatedPercentile, _) {
            final indicatorLeft =
                (constraints.maxWidth - 28) * animatedPercentile;

            return SizedBox(
              height: 56,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 18,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    left: 0,
                    child: Container(
                      width: constraints.maxWidth * animatedPercentile,
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                  ),
                  Positioned(
                    left: indicatorLeft,
                    top: 6,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.goldLight),
                        boxShadow: AppShadows.card,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.flight_rounded,
                        size: 15,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Text(
                      '0%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textTertiary,
                              ) ??
                          const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Text(
                      '100%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textTertiary,
                              ) ??
                          const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ComparisonMetricBar extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double ratio;
  final IconData icon;
  final Gradient gradient;

  const _ComparisonMetricBar({
    required this.label,
    required this.valueLabel,
    required this.ratio,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedRatio = ratio.clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
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
              ),
              Text(
                valueLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ) ??
                    const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: normalizedRatio),
              duration: AppMotion.slow,
              curve: AppMotion.standard,
              builder: (context, animatedRatio, _) {
                return Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 10,
                      color: AppColors.surfaceVariant,
                    ),
                    FractionallySizedBox(
                      widthFactor: animatedRatio,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(gradient: gradient),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InsightTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.info),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ) ??
                const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ) ??
                const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
