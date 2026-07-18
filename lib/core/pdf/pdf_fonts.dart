import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Loads the NotoSans font (bundled in `assets/fonts/`) for PDF generation.
///
/// The default PDF font (Helvetica, built into the `pdf` package) has NO
/// Unicode support — French accents (é, à, ç), the em-dash (—), curly quotes
/// and the € sign are all dropped or replaced. For a LEGAL document (the F09
/// attestation de cession and registre d'élevage), that is unacceptable: the
/// breeder's name, the buyer's address, the cession clause all carry accented
/// characters that MUST render. NotoSans is bundled (OFL license) and covers
/// the full Latin range.
///
/// The font is loaded once and cached for the process lifetime — PDF
/// generation may happen back-to-back (multiple puppies) and re-reading a
/// 2 MB asset per call would be wasteful.
///
/// Testability: [loadFromBundle] is the production path (reads the bundled
/// asset via [rootBundle]). [loadFromBytes] lets unit tests inject font bytes
/// without a live asset bundle. Both populate the same singletons.
class PdfFonts {
  PdfFonts._();

  static pw.Font? _regular;
  static pw.Font? _bold;

  /// Loads the fonts from the bundled asset (production path). Idempotent.
  static Future<void> loadFromBundle() async {
    if (_regular != null && _bold != null) return;
    // NotoSans variable covers Regular and Bold through the same file; we
    // register the same bytes for both faces and let the TextStyle.fontWeight
    // differentiate. (Variable-font faux-bold is acceptable for a sober
    // administrative document; bundling a separate Bold file would double the
    // asset weight.)
    final data = await rootBundle.load('assets/fonts/NotoSans.ttf');
    _apply(data);
  }

  /// Loads the fonts from explicit bytes (test path). Idempotent per session.
  static void loadFromBytes(ByteData data) {
    if (_regular != null && _bold != null) return;
    _apply(data);
  }

  /// Resets the cache. Test-only — production never needs to reload.
  static void reset() {
    _regular = null;
    _bold = null;
  }

  static void _apply(ByteData data) {
    _regular = pw.Font.ttf(data);
    _bold = pw.Font.ttf(data);
  }

  static pw.Font get regular {
    _assertLoaded();
    return _regular!;
  }

  static pw.Font get bold {
    _assertLoaded();
    return _bold!;
  }

  /// A [pw.ThemeData] with NotoSans as the default font, so [pw.MultiPage]
  /// and its children render Unicode correctly without per-widget overrides.
  static pw.ThemeData get theme => pw.ThemeData.withFont(
    base: regular,
    bold: bold,
  );

  static void _assertLoaded() {
    if (_regular == null || _bold == null) {
      throw StateError(
        'PdfFonts must be loaded before any PDF is generated '
        '(call loadFromBundle in production, loadFromBytes in tests).',
      );
    }
  }
}
