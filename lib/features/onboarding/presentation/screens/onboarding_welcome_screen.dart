import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Center(
                child: Icon(
                  Icons.pets_rounded,
                  size: 96,
                  color: Color(0xFFC4664A),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Bienvenue sur Portea',
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitle,
              ),
              const SizedBox(height: 16),
              Text(
                'Suivez vos portées de la mise bas à la cession, paperasse comprise.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go('/onboarding/setup'),
                child: const Text('Commencer'),
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
