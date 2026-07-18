import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:portea_client/portea_client.dart';

import 'pdf_fonts.dart';

/// Builds the cession attestation PDF for a sold puppy (F09).
///
/// This is a LEGAL document — the model is the official French "attestation
/// de cession" required by the DDPP for the sale of a companion animal. The
/// layout is deliberately sober and administrative: black text on white, a
/// clear block structure (breeder / animal / buyer / signatures), no graphic
/// flourish. The DDPP cares about completeness and legibility, not branding.
///
/// Data sources (all fetched from Serverpod upstream — this template never
/// hits the network itself):
/// - [kennel] : the breeder's identity (name, affix, SIRET, owner contact).
/// - [litter] : the litter's birth date (the puppy's date of birth).
/// - [puppy] : the sold animal (name, sex, color, chipNumber, buyer dossier,
///   `cessionDate`).
/// - [mother] : the dam, used to derive the breed (puppies have no `breed`
///   field of their own — it is inherited from the mother).
///
/// DATE RULE: the cession date printed here is `puppy.cessionDate` — the date
/// the sale was recorded in F08 — NEVER `DateTime.now()`. The date of the act
/// is what makes the document legally valid; the generation timestamp is an
/// implementation detail that has no place on the printed page.
///
/// chipNumber: may be null (the chip is implanted weeks after birth, the
/// attestation may be requested before). The document prints "Non renseigné"
/// in that case — the UI asks for explicit consent before generating without
/// a chip (see `DocumentsScreen`), this template simply renders the truth.
///
/// Returns the PDF bytes. Never throws for missing optional data — a missing
/// optional field renders as "Non renseigné". Throws only for structural
/// errors (a null puppy/litter/kennel would be a programming bug upstream).
Future<Uint8List> buildCessionPdf({
  required Kennel kennel,
  required Litter litter,
  required Puppy puppy,
  required Breeder? mother,
}) async {
  // Load the Unicode font BEFORE building — the default Helvetica font drops
  // French accents, which is unacceptable on a legal document. Idempotent.
  await PdfFonts.loadFromBundle();

  final doc = pw.Document(theme: PdfFonts.theme);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: _buildHeader,
      build: (context) => [
        _buildTitle(),
        pw.SizedBox(height: 12),
        _buildIntro(kennel),
        pw.SizedBox(height: 20),
        _buildSection('ÉLEVEUR', _breederRows(kennel)),
        pw.SizedBox(height: 16),
        _buildSection('ANIMAL CÉDÉ', _animalRows(puppy, litter, mother)),
        pw.SizedBox(height: 16),
        _buildSection('ACQUÉREUR', _buyerRows(puppy)),
        pw.SizedBox(height: 16),
        _buildCessionClause(puppy),
        pw.SizedBox(height: 32),
        _buildSignatures(),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _buildHeader(pw.Context context) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        'ATTESTATION DE CESSION',
        style: pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey600,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.Text(
        'Document généré par Portea',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
      ),
    ],
  );
}

pw.Widget _buildTitle() {
  return pw.Center(
    child: pw.Column(
      children: [
        pw.Text(
          'ATTESTATION DE CESSION D\'UN ANIMAL',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Article L.214-6 du Code rural et de la pêche maritime',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    ),
  );
}

pw.Widget _buildIntro(Kennel kennel) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Text(
      'Je soussigné(e) ${kennel.ownerName ?? kennel.name}, '
      'éleveur(se), certifie céder l\'animal ci-dessous décrit à l\'acquéreur '
      'désigné en bas du présent document.',
      style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.4),
    ),
  );
}

pw.Widget _buildSection(String title, List<pw.Widget> rows) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const pw.BoxDecoration(
          color: PdfColors.black,
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    ],
  );
}

pw.Widget _row(String label, String? value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 180,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value == null || value.trim().isEmpty ? 'Non renseigné' : value,
            style: pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    ),
  );
}

List<pw.Widget> _breederRows(Kennel kennel) {
  return [
    _row('Nom de l\'élevage', kennel.name),
    _row('Affixe', kennel.affix),
    _row('Éleveur(se)', kennel.ownerName),
    _row('Adresse', kennel.ownerAddress),
    _row('Téléphone', kennel.ownerPhone),
    _row('E-mail', kennel.ownerEmail),
    _row('SIRET', kennel.siret),
  ];
}

List<pw.Widget> _animalRows(Puppy puppy, Litter litter, Breeder? mother) {
  return [
    _row('Nom', puppy.name),
    _row('Sexe', _sexLabel(puppy.sex)),
    _row('Race', mother?.breed),
    _row('Robe', puppy.color),
    _row('Date de naissance', _formatDate(litter.birthDate)),
    _row('N° d\'identification (I-CAD)', puppy.chipNumber),
  ];
}

List<pw.Widget> _buyerRows(Puppy puppy) {
  return [
    _row('Nom de l\'acquéreur', puppy.buyerName),
    _row('Adresse', puppy.buyerAddress),
    _row('Téléphone', puppy.buyerPhone),
    _row('E-mail', puppy.buyerEmail),
  ];
}

pw.Widget _buildCessionClause(Puppy puppy) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CESSION',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'La cession est intervenue le ${_formatDate(puppy.cessionDate)}. '
          'L\'animal est remis à l\'acquéreur en bonne santé, exempt de toute '
          'maladie apparente au moment de la cession. Le présent document est '
          'remis à l\'acquéreur au moment de la cession.',
          style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.4),
        ),
      ],
    ),
  );
}

pw.Widget _buildSignatures() {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      _signatureBlock('L\'éleveur(se)', 200),
      _signatureBlock('L\'acquéreur(e)', 200),
    ],
  );
}

pw.Widget _signatureBlock(String label, double width) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Fait à _______________, le _______________',
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        '(Signature)',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
      ),
    ],
  );
}

String _sexLabel(String? sex) {
  switch (sex?.toLowerCase()) {
    case 'male':
      return 'Mâle';
    case 'female':
      return 'Femelle';
    default:
      return sex ?? 'Non renseigné';
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Non renseigné';
  final d = date.toLocal();
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
