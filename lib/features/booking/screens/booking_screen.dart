import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_airlines/core/theme/app_colors.dart';
import 'package:royal_airlines/core/theme/app_spacing.dart';
import 'package:royal_airlines/features/booking/controller/booking_controller.dart';
import 'package:royal_airlines/features/booking/widgets/baggage_selector.dart';
import 'package:royal_airlines/features/booking/widgets/booking_summary.dart';
import 'package:royal_airlines/features/booking/widgets/checkout_button.dart';
import 'package:royal_airlines/features/booking/widgets/fare_selector.dart';
import 'package:royal_airlines/features/booking/widgets/passenger_form.dart';
import 'package:royal_airlines/features/booking/widgets/payment_form.dart';
import 'package:royal_airlines/features/booking/widgets/seat_selector.dart';
import 'package:royal_airlines/features/booking/widgets/success_view.dart';
import 'package:royal_airlines/features/booking/widgets/travel_extras_selector.dart';
import 'package:royal_airlines/features/flights/widgets/airline_info.dart';
import 'package:royal_airlines/features/flights/widgets/flight_time_card.dart';
import 'package:royal_airlines/features/reservations/repository/reservations_store.dart';
import 'package:royal_airlines/models/flight_model.dart';
import 'package:royal_airlines/models/passenger_model.dart';
import 'package:royal_airlines/models/payment_model.dart';
import 'package:royal_airlines/shared/widgets/section_title.dart';

/// BookingScreen
/// -------------
/// Pantalla completa de reserva. Al confirmar el pago exitosamente, la
/// reserva se agrega automáticamente al [ReservationsStore] GLOBAL.
class BookingScreen extends StatelessWidget {
  final FlightModel flight;
  final FareModel initialFare;
  final int requiredSeatCount;

  const BookingScreen({
    super.key,
    required this.flight,
    required this.initialFare,
    required this.requiredSeatCount,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingController(
        flight: flight,
        initialFare: initialFare,
        requiredSeatCount: requiredSeatCount,
      ),
      child: const _BookingScreenBody(),
    );
  }
}

class _BookingScreenBody extends StatefulWidget {
  const _BookingScreenBody();

  @override
  State<_BookingScreenBody> createState() => _BookingScreenBodyState();
}

class _BookingScreenBodyState extends State<_BookingScreenBody> {
  final _formKey = GlobalKey<FormState>();
  late List<PassengerFormControllers> _passengerControllers;
  final _paymentControllers = PaymentFormControllers();

  bool _reservationSaved = false;

  @override
  void initState() {
    super.initState();
    final controller = context.read<BookingController>();
    _passengerControllers = List.generate(
      controller.requiredSeatCount,
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

  Future<void> _handleConfirm(BookingController controller) async {
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
    if (!controller.hasRequiredSeats) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selecciona ${controller.requiredSeatCount} asiento(s) para continuar',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final passengers = _passengerControllers
        .map(
          (c) => PassengerModel(
            fullName: c.fullNameController.text.trim(),
            documentNumber: c.documentController.text.trim(),
            birthDate: c.birthDate!,
          ),
        )
        .toList();

    final cardDigits =
        _paymentControllers.cardNumberController.text.replaceAll(' ', '');
    final payment = PaymentModel(
      cardHolderName: _paymentControllers.cardHolderController.text.trim(),
      maskedCardNumber:
          '•••• •••• •••• ${cardDigits.length >= 4 ? cardDigits.substring(cardDigits.length - 4) : cardDigits}',
      expiry: _paymentControllers.expiryController.text.trim(),
    );

    await controller.confirmBooking(passengers: passengers, payment: payment);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingController>();

    if (controller.status == BookingStatus.success &&
        controller.reservation != null) {
      if (!_reservationSaved) {
        _reservationSaved = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<ReservationsStore>().add(controller.reservation!);
        });
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SuccessView(reservation: controller.reservation!),
      );
    }

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
            color: AppColors.textPrimary,
          ),
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
                    _FlightSummaryCard(flight: controller.flight),
                    const SizedBox(height: AppSpacing.xl),
                    FareSelector(
                      flight: controller.flight,
                      selected: controller.selectedFare,
                      onChanged: controller.setFare,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SeatSelector(
                      flightId: controller.flight.id,
                      selectedSeats: controller.selectedSeats,
                      requiredSeatCount: controller.requiredSeatCount,
                      onSeatTapped: controller.toggleSeat,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    BaggageSelector(
                      selected: controller.baggageOption,
                      onChanged: controller.setBaggageOption,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TravelExtrasSelector(
                      hasTravelInsurance: controller.hasTravelInsurance,
                      hasPriorityBoarding: controller.hasPriorityBoarding,
                      onTravelInsuranceChanged: controller.setTravelInsurance,
                      onPriorityBoardingChanged: controller.setPriorityBoarding,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SectionTitle(
                      title:
                          'Datos de pasajeros (${controller.requiredSeatCount})',
                    ),
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
                    BookingSummary(
                      flight: controller.flight,
                      fare: controller.selectedFare,
                      passengerCount: controller.requiredSeatCount,
                      baggageOption: controller.baggageOption,
                      seatCharge: controller.seatCharge,
                      travelExtrasCharge: controller.travelExtrasPrice,
                      totalPrice: controller.totalPrice,
                    ),
                    if (controller.status == BookingStatus.error &&
                        controller.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _ErrorBanner(message: controller.errorMessage!),
                    ],
                  ],
                ),
              ),
              CheckoutButton(
                totalPrice: controller.totalPrice,
                isLoading: controller.isLoading,
                onPressed: () => _handleConfirm(controller),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlightSummaryCard extends StatelessWidget {
  final FlightModel flight;
  const _FlightSummaryCard({required this.flight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AirlineInfo(
              airline: flight.airline, flightNumber: flight.flightNumber),
          const SizedBox(height: AppSpacing.md + 1),
          FlightTimeCard(
            departureTime: flight.departureTime,
            arrivalTime: flight.arrivalTime,
            duration: flight.duration,
            stopsLabel: flight.stopsLabel,
            isDirect: flight.isDirect,
            originCode: flight.origin.code,
            destinationCode: flight.destination.code,
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
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
