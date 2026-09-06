import 'package:flutter/material.dart';
import 'package:royal_airlines/core/theme/app_colors.dart';
import 'package:royal_airlines/features/home/repository/home_repository.dart';

/// PromotionSlider
/// ---------------
/// Tarjetas más grandes (160 de alto), con patrón decorativo de líneas
/// diagonales doradas y badge de descuento con sombra propia — un
/// look mucho más "campaña publicitaria de aerolínea premium".
class PromotionSlider extends StatefulWidget {
  final List<PromotionModel> promotions;

  const PromotionSlider({super.key, required this.promotions});

  @override
  State<PromotionSlider> createState() => _PromotionSliderState();
}

class _PromotionSliderState extends State<PromotionSlider> {
  late final PageController _pageController =
      PageController(viewportFraction: 0.88);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() => _page = _pageController.page ?? 0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.promotions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.promotions.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _PromotionCard(promotion: widget.promotions[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.promotions.length, (index) {
            final bool isActive = (_page.round() == index);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                gradient: isActive ? AppColors.goldGradient : null,
                color: isActive ? null : AppColors.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final PromotionModel promotion;
  const _PromotionCard({required this.promotion});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Círculos decorativos dorados translúcidos.
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.14)),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -50,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.08)),
              ),
            ),
            Positioned(
              left: -10,
              bottom: -10,
              child: Icon(Icons.flight_takeoff_rounded,
                  size: 90,
                  color: AppColors.textOnPrimary.withValues(alpha: 0.04)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.4),
                            blurRadius: 10),
                      ],
                    ),
                    child: Text(
                      promotion.discountLabel,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotion.title,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promotion.subtitle,
                        style: TextStyle(
                            fontSize: 12.5,
                            color:
                                AppColors.textOnPrimary.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
