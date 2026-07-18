import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portea_client/portea_client.dart';

import '../../../../core/errors/operation_state.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../view_models/documents_view_model.dart';

/// Documents screen (F09) — generates two legal PDFs from real data.
///
/// Replaces the pre-F09 stub (an AlertDialog claiming "PDF généré" with zero
/// generation — review verdict 2.2). The two documents:
/// - the ATTESTATION DE CESSION (per sold puppy): generated → uploaded to the
///   private Serverpod storage → success snackbar fires ONLY after the server
///   confirms the upload. No stub, no premature "success".
/// - the REGISTRE D'ÉLEVAGE (per kenned): generated → native share sheet. No
///   upload, no archival.
///
/// The "Fiche d'accompagnement" entry that used to live here is removed (it
/// is ROADMAP). The screen shows 2 entries, no more.
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
      context.read<DocumentsViewModel>().loadDocumentData(widget.litterId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DocumentsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Documents Portée')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: switch (vm.state) {
              OperationState.loading => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              OperationState.error when vm.kennel == null => _ErrorState(
                message: vm.errorMessage,
                onRetry: () => context
                    .read<DocumentsViewModel>()
                    .loadDocumentData(widget.litterId),
              ),
              _ => _DocumentsBody(litterId: widget.litterId),
            },
          ),
        ),
      ),
    );
  }
}

class _DocumentsBody extends StatelessWidget {
  final int litterId;

  const _DocumentsBody({required this.litterId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DocumentsViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Génération de documents', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          Text(
            'Générez vos PDF officiels pré-remplis à partir des données de la portée.',
            style: AppTextStyles.captionLabel,
          ),
          const SizedBox(height: 20),
          _CessionCard(litterId: litterId),
          const SizedBox(height: 12),
          _RegistreCard(),
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorMessage(message: vm.errorMessage!),
          ],
        ],
      ),
    );
  }
}

/// The cession attestation card. Shows one sub-entry per SOLD puppy of the
/// loaded litter (only sold puppies can be attested). Each puppy gets its own
/// generate button — the attestation is per-puppy, not per-litter.
class _CessionCard extends StatelessWidget {
  final int litterId;

  const _CessionCard({required this.litterId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DocumentsViewModel>();
    final soldPuppies = vm.puppies.where((p) => p.status == 'sold').toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attestation de cession',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Document légal pré-rempli, téléversé et archivé.',
                        style: AppTextStyles.captionLabel,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (soldPuppies.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aucun chiot vendu dans cette portée. La cession se déclare '
                  'depuis la fiche chiot.',
                  style: AppTextStyles.captionLabel,
                ),
              )
            else
              ...soldPuppies.map((p) => _PuppyCessionTile(puppy: p)),
          ],
        ),
      ),
    );
  }
}

class _PuppyCessionTile extends StatelessWidget {
  final Puppy puppy;

  const _PuppyCessionTile({required this.puppy});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DocumentsViewModel>();
    final hasChip = (puppy.chipNumber ?? '').trim().isNotEmpty;
    // The double-submit guard: this tile's button is disabled while ANY
    // mutation is in flight (the VM is single-flight across the screen).
    final busy = vm.isBusy;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(puppy.name, style: AppTextStyles.body),
                if (!hasChip)
                  Text(
                    'Sans n° de puce — l\'attestation portera « Non renseigné ».',
                    style: AppTextStyles.captionLabel.copyWith(
                      color: AppColors.statusReserved,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: busy
                ? null
                : () => _onGenerate(context, hasChip: hasChip),
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Générer'),
          ),
        ],
      ),
    );
  }

  Future<void> _onGenerate(
    BuildContext context, {
    required bool hasChip,
  }) async {
    final vm = context.read<DocumentsViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // INFORMED CONSENT (F09 rule): generating without a chip is allowed but
    // never silent. The user must confirm they accept "Non renseigné" on the
    // legal document — the chip can be added later and the attestation
    // regenerated.
    if (!hasChip) {
      final confirmed = await _confirmChipMissing(context);
      if (!confirmed) return;
    }

    final doc = await vm.generateCessionPdf(puppy);

    if (!context.mounted) return;

    // SUCCESS fires ONLY here — after the server returned an IssuedDocument.
    // No premature snackbar, no stub dialog (verdict 2.2).
    if (doc != null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Attestation générée et archivée.'),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            vm.errorMessage ?? 'La génération a échoué. Réessayez.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<bool> _confirmChipMissing(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aucun numéro de puce'),
        content: const Text(
          'Ce chiot n\'a pas de numéro d\'identification (I-CAD). '
          'L\'attestation portera la mention « Non renseigné » sur la ligne '
          'prévue. Vous pourrez la régénérer après l\'implantation de la puce.\n\n'
          'Générer quand même ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Générer'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _RegistreCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DocumentsViewModel>();
    final busy = vm.isBusy;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(
          Icons.picture_as_pdf_rounded,
          color: AppColors.error,
          size: 36,
        ),
        title: Text(
          'Registre d\'élevage',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Toutes les portées — régénéré à la demande, non archivé.',
              style: AppTextStyles.captionLabel,
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: busy ? null : () => _onShare(context),
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Générer & partager'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onShare(BuildContext context) async {
    final vm = context.read<DocumentsViewModel>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final ok = await vm.generateRegistrePdf();
    if (!context.mounted) return;
    // The share sheet itself is the "success" UI — no extra snackbar on
    // success. Only surface failures.
    if (!ok) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            vm.errorMessage ?? 'La génération du registre a échoué.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            message ?? 'Impossible de charger les données.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppTextStyles.captionLabel),
          ),
        ],
      ),
    );
  }
}
