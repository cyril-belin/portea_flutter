import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'status_badge_widget.dart';

class AnimalListTile extends StatelessWidget {
  final String name;
  final String sex; // 'male' | 'female'
  final String? subtitle;
  final String? status;
  final String? photoUrl;
  final VoidCallback onTap;

  const AnimalListTile({
    super.key,
    required this.name,
    required this.sex,
    this.subtitle,
    this.status,
    this.photoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFemale = sex.toLowerCase() == 'female' || sex == '♀';
    final avatarColor = isFemale
        ? AppColors.female.withValues(alpha: 0.15)
        : AppColors.male.withValues(alpha: 0.15);
    final iconColor = isFemale ? AppColors.female : AppColors.male;
    final sexIcon = isFemale ? '♀' : '♂';

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: avatarColor,
          backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
              ? NetworkImage(photoUrl!)
              : null,
          child: photoUrl == null || photoUrl!.isEmpty
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: iconColor,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              sexIcon,
              style: TextStyle(
                color: iconColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: AppTextStyles.captionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: status != null
            ? StatusBadgeWidget(status: status!)
            : const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
      ),
    );
  }
}
