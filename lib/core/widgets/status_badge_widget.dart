import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StatusBadgeWidget extends StatelessWidget {
  final String status;

  const StatusBadgeWidget({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'available':
      case 'disponible':
        bg = AppColors.statusAvailableBg;
        text = AppColors.statusAvailableText;
        label = 'Disponible';
        break;
      case 'reserved':
      case 'réservé':
        bg = AppColors.statusReservedBg;
        text = AppColors.statusReservedText;
        label = 'Réservé';
        break;
      case 'sold':
      case 'vendu':
        bg = AppColors.statusSoldBg;
        text = AppColors.statusSoldText;
        label = 'Vendu';
        break;
      default:
        bg = AppColors.border;
        text = AppColors.textPrimary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionLabel.copyWith(
          color: text,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
