import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:royal_airlines/core/theme/app_colors.dart';
import 'package:royal_airlines/core/theme/app_spacing.dart';
import 'package:royal_airlines/core/theme/app_theme.dart';
import 'package:royal_airlines/models/reservation_model.dart';

class BoardingPassCard extends StatelessWidget {
  final ReservationModel reservation;

  const BoardingPassCard({super.key, required this.reservation});

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final flight = reservation.flight;
    final passenger = reservation.passengers.isNotEmpty
        ? reservation.passengers.first.fullName
        : 'Pasajero principal';
    final qrData = [
      'ROYAL-AIRLINES',
      reservation.confirmationCode,
      passenger,
      '${flight.origin.code}-${flight.destination.code}',
      flight.departureTime.toIso8601String(),
    ].join('|');
    final isUpcoming = flight.departureTime.isAfter(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.glassGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
        boxShadow: [...AppShadows.floating, ...AppShadows.goldGlow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
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
                          color: AppColors.glassOverlay,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Icon(
                          Icons.airplane_ticket_rounded,
                          color: AppColors.gold,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ROYAL AIRLINES',
                              style: TextStyle(
                                color: AppColors.goldLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              'BOARDING PASS DIGITAL',
                              style: TextStyle(
                                color: AppColors.textOnPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _BoardingStatusChip(isUpcoming: isUpcoming),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: _AirportPanel(
                          code: flight.origin.code,
                          city: flight.origin.city,
                          label: 'Salida',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.glassOverlay,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: const Icon(
                                Icons.flight_rounded,
                                color: AppColors.gold,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _formatDuration(flight.duration),
                              style: const TextStyle(
                                color: AppColors.goldLight,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _AirportPanel(
                          code: flight.destination.code,
                          city: flight.destination.city,
                          label: 'Llegada',
                          alignment: CrossAxisAlignment.end,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _GlassFact(
                        label: 'Vuelo',
                        value: flight.flightNumber,
                      ),
                      _GlassFact(
                        label: 'Asiento',
                        value: reservation.seats.join(', '),
                      ),
                      _GlassFact(
                        label: 'Clase',
                        value: reservation.fare.tierName,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 28),
                    painter: _PerforatedBoardingLinePainter(),
                  ),
                  const Positioned(
                    left: -14,
                    child: _TicketNotch(),
                  ),
                  const Positioned(
                    right: -14,
                    child: _TicketNotch(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BoardingFact(
                              title: 'Pasajero',
                              value: passenger,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _BoardingFact(
                              title: 'Fecha',
                              value:
                                  '${_formatDate(flight.departureTime)} · ${_formatTime(flight.departureTime)}',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _BoardingFact(
                              title: 'Aeronave',
                              value: flight.aircraft,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _BoardingFact(
                              title: 'Reserva',
                              value: reservation.confirmationCode,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.card,
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 168,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.primaryDark,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMd,
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Escanea este QR durante el check-in y en puerta de embarque.',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _BarcodeStrip(data: qrData),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Código de abordaje',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              reservation.confirmationCode,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _BoardingStatusChip extends StatelessWidget {
  final bool isUpcoming;

  const _BoardingStatusChip({required this.isUpcoming});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isUpcoming
            ? AppColors.goldLight
            : AppColors.textOnPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isUpcoming ? AppColors.gold : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        isUpcoming ? 'LISTO PARA CHECK-IN' : 'VUELO COMPLETADO',
        style: TextStyle(
          color: isUpcoming ? AppColors.primaryDark : AppColors.textOnPrimary,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AirportPanel extends StatelessWidget {
  final String code;
  final String city;
  final String label;
  final CrossAxisAlignment alignment;
  final TextAlign textAlign;

  const _AirportPanel({
    required this.code,
    required this.city,
    required this.label,
    this.alignment = CrossAxisAlignment.start,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          textAlign: textAlign,
          style: const TextStyle(
            color: AppColors.goldLight,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          code,
          textAlign: textAlign,
          style: const TextStyle(
            color: AppColors.textOnPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          city,
          textAlign: textAlign,
          style: TextStyle(
            color: AppColors.textOnPrimary.withValues(alpha: 0.78),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GlassFact extends StatelessWidget {
  final String label;
  final String value;

  const _GlassFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.glassOverlay,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: AppColors.textOnPrimary.withValues(alpha: 0.76),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketNotch extends StatelessWidget {
  const _TicketNotch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PerforatedBoardingLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.36)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const dashWidth = 8.0;
    const dashSpace = 5.0;
    double startX = 16;
    final centerY = size.height / 2;

    while (startX < size.width - 16) {
      canvas.drawLine(
        Offset(startX, centerY),
        Offset(startX + dashWidth, centerY),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BoardingFact extends StatelessWidget {
  final String title;
  final String value;

  const _BoardingFact({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _BarcodeStrip extends StatelessWidget {
  final String data;

  const _BarcodeStrip({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(42, (index) {
          final code = data.codeUnitAt(index % data.length);
          final height = 20 + (code % 28).toDouble();
          final isThick = code.isEven;

          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Container(
              width: isThick ? 3.4 : 1.8,
              height: height,
              decoration: BoxDecoration(
                color: index % 5 == 0
                    ? AppColors.primaryDark
                    : AppColors.primary.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }),
      ),
    );
  }
}