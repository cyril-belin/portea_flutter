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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (status.toLowerCase()) {
      case 'available':
      case 'disponible':
        bg = isDark
            ? AppColors.statusAvailable.withValues(alpha: 0.15)
            : AppColors.statusAvailableBg;
        text = isDark ? AppColors.statusAvailable : AppColors.statusAvailableText;
        label = 'Disponible';
        break;
      case 'reserved':
      case 'réservé':
        bg = isDark
            ? AppColors.statusReserved.withValues(alpha: 0.15)
            : AppColors.statusReservedBg;
        text = isDark ? AppColors.statusReserved : AppColors.statusReservedText;
        label = 'Réservé';
        break;
      case 'sold':
      case 'vendu':
        bg = isDark
            ? AppColors.statusSold.withValues(alpha: 0.15)
            : AppColors.statusSoldBg;
        text = isDark ? AppColors.statusSold : AppColors.statusSoldText;
        label = 'Vendu';
        break;
      default:
        bg = isDark ? AppColors.darkBorder : AppColors.border;
        text = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
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
