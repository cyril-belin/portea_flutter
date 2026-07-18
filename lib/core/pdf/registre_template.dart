import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:portea_client/portea_client.dart';

import 'pdf_fonts.dart';

/// Builds the breeding registry PDF (F09) — the "registre des entrées et
/// sorties" required by the DDPP for any breeding establishment.
///
/// This is an ADMINISTRATIVE document, regenerated on demand: every call
/// produces a fresh snapshot of all litters (active + closed) and their
/// puppies. It is never archived server-side (no `IssuedDocument` row), only
/// shared via `Printing.sharePdf()`.
///
/// Layout: one row per puppy, grouped by litter. Columns are kept to the
/// legal minimum (name, sex, status, cession date if sold, buyer). Sober
/// black-on-white — no graphic flourish, this is a registry, not marketing.
///
/// Data sources (all fetched upstream):
/// - [kennel] : the establishment's identity (header).
/// - [litters] : every litter of the kennel, sorted most-recent first.
/// - [mothers] : map `motherId → Breeder` to resolve the dam's name and breed
///   without an N+1 per row.
/// - [puppiesByLitter] : map `litterId → List<Puppy>` for the rows.
///
/// Returns the PDF bytes. Never throws for missing optional fields — a puppy
/// with no buyer renders empty cells, a litter with an unknown dam renders
/// "Mère inconnue". A truly empty kennel (no litters) still produces a valid
/// one-page document stating "Aucune portée enregistrée."
Future<Uint8List> buildRegistrePdf({
  required Kennel kennel,
  required List<Litter> litters,
  required Map<int, Breeder?> mothers,
  required Map<int, List<Puppy>> puppiesByLitter,
}) async {
  // Load the Unicode font BEFORE building — the default Helvetica font drops
  // French accents, which is unacceptable on a legal document. Idempotent.
  await PdfFonts.loadFromBundle();

  final doc = pw.Document(theme: PdfFonts.theme);

  // Most recent litters first — matches the LittersViewModel ordering and
  // gives the reader the active portées at the top.
  final sorted = [...litters]
    ..sort((a, b) => b.birthDate.compareTo(a.birthDate));

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (context) => _buildHeader(kennel),
      build: (context) {
        if (sorted.isEmpty) {
          return [
            pw.SizedBox(height: 60),
            pw.Center(
              child: pw.Text(
                'Aucune portée enregistrée.',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
            ),
          ];
        }
        final blocks = <pw.Widget>[];
        for (final litter in sorted) {
          blocks.add(_buildLitterBlock(litter, mothers, puppiesByLitter));
          blocks.add(pw.SizedBox(height: 16));
        }
        return blocks;
      },
    ),
  );

  return doc.save();
}

pw.Widget _buildHeader(Kennel kennel) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 8),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.black, width: 1),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'REGISTRE D\'ÉLEVAGE',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              '${kennel.name}${kennel.affix != null && kennel.affix!.isNotEmpty ? ' — affixe « ${kennel.affix} »' : ''}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Édité le ${_formatDate(DateTime.now().toLocal())}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _buildLitterBlock(
  Litter litter,
  Map<int, Breeder?> mothers,
  Map<int, List<Puppy>> puppiesByLitter,
) {
  final mother = mothers[litter.motherId];
  final puppies = puppiesByLitter[litter.id] ?? const <Puppy>[];
  final sortedPuppies = [...puppies]
    ..sort((a, b) {
      final ai = a.id ?? 0;
      final bi = b.id ?? 0;
      return ai.compareTo(bi);
    });

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: PdfColors.grey200,
        child: pw.Text(
          'Portée du ${_formatDate(litter.birthDate)} — '
          'Mère : ${mother?.name ?? 'Inconnue'}'
          '${mother?.breed != null && mother!.breed!.isNotEmpty ? ' (${mother.breed})' : ''}',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      pw.SizedBox(height: 4),
      _buildPuppyTable(sortedPuppies),
    ],
  );
}

pw.Widget _buildPuppyTable(List<Puppy> puppies) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(3), // Nom
      1: pw.FixedColumnWidth(40), // Sexe
      2: pw.FlexColumnWidth(2), // Statut
      3: pw.FlexColumnWidth(2.5), // Date de cession
      4: pw.FlexColumnWidth(4), // Acquéreur
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children:
            const [
                  'Nom',
                  'Sexe',
                  'Statut',
                  'Cession',
                  'Acquéreur',
                ]
                .map(
                  (h) => pw.Padding(
                    padding: pw.EdgeInsets.all(5),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
      ...puppies.map((p) => pw.TableRow(children: _puppyRow(p))),
      if (puppies.isEmpty)
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Aucun chiot enregistré pour cette portée.',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
            ),
            for (final _ in [1, 2, 3, 4])
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(''),
              ),
          ],
        ),
    ],
  );
}

List<pw.Widget> _puppyRow(Puppy p) {
  return [
    _cell(p.name),
    _cell(_sexLabel(p.sex)),
    _cell(_statusLabel(p.status)),
    _cell(
      p.status == 'sold' && p.cessionDate != null
          ? _formatDate(p.cessionDate!)
          : '',
    ),
    _cell(p.status == 'sold' ? p.buyerName : ''),
  ];
}

pw.Widget _cell(String? text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Text(
      text ?? '',
      style: const pw.TextStyle(fontSize: 9),
    ),
  );
}

String _sexLabel(String? sex) {
  switch (sex?.toLowerCase()) {
    case 'male':
      return 'M';
    case 'female':
      return 'F';
    default:
      return sex ?? '–';
  }
}

String _statusLabel(String? status) {
  switch (status) {
    case 'available':
      return 'Disponible';
    case 'reserved':
      return 'Réservé';
    case 'sold':
      return 'Vendu';
    default:
      return status ?? '–';
  }
}

String _formatDate(DateTime date) {
  final d = date.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}
