import 'package:flutter/material.dart';
import 'package:royal_airlines/core/theme/app_colors.dart';
import 'package:royal_airlines/core/theme/app_spacing.dart';
import 'package:royal_airlines/features/home/widgets/selector_field.dart';
import 'package:royal_airlines/models/travel_class.dart';

/// TravelClassSelector
/// -------------------
/// Selector que abre un bottom sheet con las 4 clases de viaje.
/// Espaciados ajustados a [AppSpacing].
class TravelClassSelector extends StatelessWidget {
  final TravelClass value;
  final ValueChanged<TravelClass> onChanged;

  const TravelClassSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  void _openSheet(BuildContext context) async {
    final result = await showModalBottomSheet<TravelClass>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _TravelClassSheet(selected: value),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return SelectorField(
      icon: Icons.airline_seat_recline_extra_rounded,
      label: 'Clase',
      value: value.label,
      onTap: () => _openSheet(context),
    );
  }
}

class _TravelClassSheet extends StatelessWidget {
  final TravelClass selected;
  const _TravelClassSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        14,
        AppSpacing.xxl,
        MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Clase de viaje',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...TravelClass.values.map((travelClass) {
            final bool isSelected = travelClass == selected;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(travelClass),
                borderRadius: BorderRadius.circular(AppSpacing.sm + 2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        size: 21,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        travelClass.label,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
