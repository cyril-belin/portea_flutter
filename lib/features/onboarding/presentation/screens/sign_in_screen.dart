import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../../../../main.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Onboarding login screen.
///
/// Uses Serverpod's [EmailSignInWidget], which handles login, registration
/// and password reset against the `emailIdp` endpoint. Google / Apple Sign-In
/// will be added here once their console configs are available.
///
/// Navigation after authentication is NOT triggered here (per Serverpod docs,
/// navigating in `onAuthenticated` would force a re-login on every launch).
/// Instead the go_router redirect reacts to the auth state change and routes
/// the user to Kennel Setup (first time) or Dashboard (existing kennel).
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Icon(
                      Icons.pets_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bienvenue sur Portea',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.screenTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous ou créez votre compte pour gérer votre élevage.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  EmailSignInWidget(
                    client: client,
                    onAuthenticated: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connexion réussie.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    onError: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Échec de l\'authentification : $error',
                          ),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    },
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
