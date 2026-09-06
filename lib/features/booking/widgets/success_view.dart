import 'package:flutter/material.dart';
import 'package:royal_airlines/core/theme/app_colors.dart';
import 'package:royal_airlines/core/theme/app_spacing.dart';
import 'package:royal_airlines/core/utils/currency_formatter.dart';
import 'package:royal_airlines/features/reservations/screens/reservation_screen.dart';
import 'package:royal_airlines/models/reservation_model.dart';
import 'package:royal_airlines/navigation/main_navigation.dart';
import 'package:royal_airlines/shared/widgets/custom_button.dart';

/// SuccessView
/// -----------
/// Pantalla de confirmación de compra. Círculo de éxito de 80px (antes
/// 88) y tarjeta de código con padding de 17px (antes 18) — mismo
/// criterio de reducción de ~8-10% aplicado a toda la app remodelada.
class SuccessView extends StatelessWidget {
  final ReservationModel reservation;

  const SuccessView({super.key, required this.reservation});

  void _goToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (route) => false,
    );
  }

  void _goToReservations(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (route) => false,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReservationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 42,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text(
              '¡Reserva confirmada!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${reservation.flight.origin.code} → ${reservation.flight.destination.code} · '
              '${reservation.flight.airline}',
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg - 4),
              ),
              child: Column(
                children: [
                  const Text(
                    'Código de confirmación',
                    style: TextStyle(fontSize: 10.5, color: AppColors.gold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reservation.confirmationCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnPrimary,
                      letterSpacing: 3.5,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '${reservation.seats.length} asiento(s) · '
                    '${CurrencyFormatter.cop(reservation.totalPrice)}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl + 4),
            CustomButton(
              label: 'Ver mis reservas',
              onPressed: () => _goToReservations(context),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => _goToHome(context),
              child: const Text(
                'Volver al inicio',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
