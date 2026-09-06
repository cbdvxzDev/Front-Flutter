import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_airlines/core/theme/app_colors.dart';
import 'package:royal_airlines/core/theme/app_spacing.dart';
import 'package:royal_airlines/core/utils/currency_formatter.dart';
import 'package:royal_airlines/features/booking/controller/trip_booking_controller.dart';
import 'package:royal_airlines/features/booking/repository/booking_repository.dart';
import 'package:royal_airlines/features/booking/widgets/booking_summary.dart';
import 'package:royal_airlines/features/booking/widgets/passenger_form.dart';
import 'package:royal_airlines/features/booking/widgets/payment_form.dart';
import 'package:royal_airlines/features/reservations/repository/reservations_store.dart';
import 'package:royal_airlines/features/reservations/screens/reservation_screen.dart';
import 'package:royal_airlines/models/passenger_model.dart';
import 'package:royal_airlines/models/payment_model.dart';
import 'package:royal_airlines/models/reservation_model.dart';
import 'package:royal_airlines/navigation/main_navigation.dart';
import 'package:royal_airlines/shared/widgets/custom_button.dart';
import 'package:royal_airlines/shared/widgets/section_title.dart';

/// CheckoutScreen
/// --------------
/// Paso final ÚNICO del viaje redondo: datos de pasajeros, pago y
/// resumen combinado de AMBOS tramos (ida + regreso). Solo se llega
/// aquí después de completar tarifa/asiento/equipaje de los dos
/// tramos en [LegBookingScreen] — los pasajeros y el pago se piden
/// una sola vez para todo el viaje, ya que viajan las mismas personas
/// en ambos tramos.
class CheckoutScreen extends StatefulWidget {
  final TripBookingController tripController;

  const CheckoutScreen({super.key, required this.tripController});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late List<PassengerFormControllers> _passengerControllers;
  final _paymentControllers = PaymentFormControllers();
  final _repository = BookingRepository();

  bool _isLoading = false;
  String? _errorMessage;
  List<ReservationModel>? _completedReservations;

  @override
  void initState() {
    super.initState();
    _passengerControllers = List.generate(
      widget.tripController.requiredSeatCount,
      (_) => PassengerFormControllers(),
    );
  }

  @override
  void dispose() {
    for (final c in _passengerControllers) {
      c.dispose();
    }
    _paymentControllers.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    FocusScope.of(context).unfocus();

    final isFormValid = _formKey.currentState!.validate();
    final missingBirthDate =
        _passengerControllers.any((c) => c.birthDate == null);

    if (!isFormValid) return;
    if (missingBirthDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Completa la fecha de nacimiento de todos los pasajeros'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final passengers = _passengerControllers
        .map((c) => PassengerModel(
              fullName: c.fullNameController.text.trim(),
              documentNumber: c.documentController.text.trim(),
              birthDate: c.birthDate!,
            ))
        .toList();

    final cardDigits =
        _paymentControllers.cardNumberController.text.replaceAll(' ', '');
    final payment = PaymentModel(
      cardHolderName: _paymentControllers.cardHolderController.text.trim(),
      maskedCardNumber:
          '•••• •••• •••• ${cardDigits.length >= 4 ? cardDigits.substring(cardDigits.length - 4) : cardDigits}',
      expiry: _paymentControllers.expiryController.text.trim(),
    );

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final outbound = widget.tripController.outbound!;
      final reservations = <ReservationModel>[
        await _repository.confirmBooking(
          flight: outbound.flight,
          fare: outbound.fare,
          seats: outbound.selectedSeats,
          passengers: passengers,
          payment: payment,
          totalPrice: outbound.totalPrice,
        ),
      ];

      if (widget.tripController.isRoundTrip) {
        final returnLeg = widget.tripController.returnLeg!;
        reservations.add(await _repository.confirmBooking(
          flight: returnLeg.flight,
          fare: returnLeg.fare,
          seats: returnLeg.selectedSeats,
          passengers: passengers,
          payment: payment,
          totalPrice: returnLeg.totalPrice,
        ));
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _completedReservations = reservations;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudo procesar el pago. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_completedReservations != null) {
      return _RoundTripSuccessView(reservations: _completedReservations!);
    }

    final tripController = widget.tripController;
    final outbound = tripController.outbound!;
    final returnLeg = tripController.returnLeg;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Confirmar reserva',
          style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  children: [
                    SectionTitle(
                        title:
                            'Datos de pasajeros (${tripController.requiredSeatCount})'),
                    const SizedBox(height: AppSpacing.md),
                    ...List.generate(_passengerControllers.length, (index) {
                      return PassengerForm(
                        passengerIndex: index,
                        controllers: _passengerControllers[index],
                      );
                    }),
                    const SizedBox(height: AppSpacing.sm),
                    PaymentForm(controllers: _paymentControllers),
                    const SizedBox(height: AppSpacing.xl),
                    SectionTitle(
                      title: returnLeg != null ? 'Resumen · Ida' : 'Resumen',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    BookingSummary(
                      flight: outbound.flight,
                      fare: outbound.fare,
                      passengerCount: tripController.requiredSeatCount,
                      baggageOption: outbound.baggageOption,
                      seatCharge: outbound.seatCharge,
                      travelExtrasCharge: outbound.travelExtrasPrice,
                      totalPrice: outbound.totalPrice,
                    ),
                    if (returnLeg != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const SectionTitle(title: 'Resumen · Regreso'),
                      const SizedBox(height: AppSpacing.md),
                      BookingSummary(
                        flight: returnLeg.flight,
                        fare: returnLeg.fare,
                        passengerCount: tripController.requiredSeatCount,
                        baggageOption: returnLeg.baggageOption,
                        seatCharge: returnLeg.seatCharge,
                        travelExtrasCharge: returnLeg.travelExtrasPrice,
                        totalPrice: returnLeg.totalPrice,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _GrandTotalRow(total: tripController.grandTotal),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _ErrorBanner(message: _errorMessage!),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 13, 20, 13),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textTertiary)),
                          Text(
                            CurrencyFormatter.cop(tripController.grandTotal),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: CustomButton(
                          label: 'Confirmar y pagar',
                          isLoading: _isLoading,
                          onPressed: _handleConfirm,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrandTotalRow extends StatelessWidget {
  final double total;
  const _GrandTotalRow({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Total del viaje (ida + regreso)',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnPrimary),
            ),
          ),
          Text(
            CurrencyFormatter.cop(total),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 17),
          const SizedBox(width: 9),
          Expanded(
              child: Text(message,
                  style:
                      const TextStyle(color: AppColors.error, fontSize: 12.5))),
        ],
      ),
    );
  }
}

/// _RoundTripSuccessView
/// ----------------------
/// Confirmación final. Muestra UN código por tramo confirmado (uno si
/// es "Solo ida" llegado por error a este flujo, dos si es redondo:
/// "Código de ida" y "Código de regreso"), más el total combinado.
/// Guarda ambas reservas en [ReservationsStore] una sola vez tras el
/// primer frame.
class _RoundTripSuccessView extends StatefulWidget {
  final List<ReservationModel> reservations;
  const _RoundTripSuccessView({required this.reservations});

  @override
  State<_RoundTripSuccessView> createState() => _RoundTripSuccessViewState();
}

class _RoundTripSuccessViewState extends State<_RoundTripSuccessView> {
  bool _saved = false;

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
    if (!_saved) {
      _saved = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final store = context.read<ReservationsStore>();
        for (final reservation in widget.reservations) {
          store.add(reservation);
        }
      });
    }

    final isRoundTrip = widget.reservations.length > 1;
    final total =
        widget.reservations.fold<double>(0, (sum, r) => sum + r.totalPrice);
    final first = widget.reservations.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 42, color: AppColors.success),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                isRoundTrip
                    ? '¡Viaje redondo confirmado!'
                    : '¡Reserva confirmada!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 7),
              Text(
                isRoundTrip
                    ? '${first.flight.origin.code} ⇄ ${first.flight.destination.code}'
                    : '${first.flight.origin.code} → ${first.flight.destination.code}',
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ...List.generate(widget.reservations.length, (index) {
                final reservation = widget.reservations[index];
                final label = !isRoundTrip
                    ? 'Código de confirmación'
                    : (index == 0 ? 'Código de ida' : 'Código de regreso');

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg - 4),
                    ),
                    child: Column(
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.gold)),
                        const SizedBox(height: 6),
                        Text(
                          reservation.confirmationCode,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textOnPrimary,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${reservation.flight.origin.code} → ${reservation.flight.destination.code} · '
                          '${reservation.seats.length} asiento(s) · ${CurrencyFormatter.cop(reservation.totalPrice)}',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textOnPrimary
                                  .withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (isRoundTrip)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Text(
                    'Total pagado: ${CurrencyFormatter.cop(total)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                ),
              CustomButton(
                  label: 'Ver mis reservas',
                  onPressed: () => _goToReservations(context)),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => _goToHome(context),
                child: const Text(
                  'Volver al inicio',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
