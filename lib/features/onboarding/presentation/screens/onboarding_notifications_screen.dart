import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../view_models/onboarding_view_model.dart';

class OnboardingNotificationsScreen extends StatefulWidget {
  const OnboardingNotificationsScreen({super.key});

  @override
  State<OnboardingNotificationsScreen> createState() =>
      _OnboardingNotificationsScreenState();
}

class _OnboardingNotificationsScreenState
    extends State<OnboardingNotificationsScreen> {
  bool _requesting = false;

  void _finish() {
    context.read<OnboardingViewModel>().completeOnboarding();
    context.go('/dashboard');
  }

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);
    try {
      // Real OS permission request. The result (granted/denied) does not
      // gate onboarding — the user can proceed either way.
      await context.read<NotificationService>().requestPermission();
    } finally {
      if (mounted) {
        setState(() => _requesting = false);
        _finish();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Center(
                    child: Icon(
                      Icons.notifications_active_rounded,
                      size: 96,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Activer les notifications',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.screenTitle,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ne ratez plus aucun rappel important pour la santé de vos chiots (vermifuges, vaccins, pesées).',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (_requesting)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: _requestPermission,
                      child: const Text('Autoriser les notifications'),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _requesting ? null : _finish,
                    child: Text(
                      'Plus tard',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
