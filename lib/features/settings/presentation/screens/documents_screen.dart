import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../view_models/settings_view_model.dart';

class DocumentsScreen extends StatefulWidget {
  final int litterId;

  const DocumentsScreen({super.key, required this.litterId});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsViewModel>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final isPremium = viewModel.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents Portée'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Génération de documents', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                Text(
                  'Générez instantanément vos PDF officiels pré-remplis.',
                  style: AppTextStyles.captionLabel,
                ),
                const SizedBox(height: 20),

                _buildDocumentTile(
                  context: context,
                  title: 'Registre des entrées & sorties (Portée)',
                  description: 'Registre d\'élevage officiel requis par la DDPP.',
                  isPremium: isPremium,
                ),
                const SizedBox(height: 12),
                _buildDocumentTile(
                  context: context,
                  title: 'Certificat de vente / Cession',
                  description:
                      'Facture et contrat de vente pré-rempli avec l\'acquéreur.',
                  isPremium: isPremium,
                ),
                const SizedBox(height: 12),
                _buildDocumentTile(
                  context: context,
                  title: 'Fiche d\'accompagnement du chiot',
                  description: 'Conseils de croissance et historique des pesées.',
                  isPremium: isPremium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTile({
    required BuildContext context,
    required String title,
    required String description,
    required bool isPremium,
  }) {
    return Card(
      child: ListTile(
        onTap: () {
          if (!isPremium) {
            context.push('/premium');
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Export du document'),
                content: const Text(
                  'Votre document PDF a été généré avec succès.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        },
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          Icons.picture_as_pdf_rounded,
          color: isPremium
              ? AppColors.error
              : (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary),
          size: 36,
        ),
        title: Text(
          title,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(description, style: AppTextStyles.captionLabel),
            if (!isPremium) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.premium.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      color: AppColors.premium,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Déverrouiller avec Premium',
                      style: TextStyle(
                        color: AppColors.premium,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: isPremium
            ? const Icon(Icons.download_rounded, color: AppColors.primary)
            : const Icon(Icons.lock_outline_rounded, color: AppColors.premium),
      ),
    );
  }
}
