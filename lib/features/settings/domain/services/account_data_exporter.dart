import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:portea_client/portea_client.dart';
import 'package:share_plus/share_plus.dart';

/// Writes a [KennelDataExport] payload to a temporary JSON file and hands it
/// to the OS share sheet.
///
/// Kept as a separate service (not inside the repository or the view model)
/// because:
/// - the repository stays a thin transport layer (server calls only);
/// - the view model stays free of dart:io / share_plus dependencies, so its
///   unit tests don't need to mock the filesystem.
///
/// The success of `share` is the success signal for the screen — the share
/// sheet was invoked. We cannot guarantee the user actually completed the
/// share (they may dismiss the sheet), but the call returning normally means
/// the JSON file was built and handed to the OS, which is all we can verify.
class AccountDataExporter {
  /// Serializes [export] to a pretty JSON file in the platform's temporary
  /// directory and opens the share sheet with that file. Returns the path
  /// that was shared (the screen ignores it; useful for logs/tests).
  Future<String> exportAndShare(KennelDataExport export) async {
    final dir = await getTemporaryDirectory();
    // Per-user filename with a UTC timestamp — multiple exports from the
    // same account land as separate files rather than overwriting each
    // other, mirroring the server-side cession path versioning pattern.
    final stamp = export.exportedAt.toIso8601String();
    final path = '${dir.path}/portea-export-$stamp.json';

    final file = File(path);
    // JsonEncoder with indentation so the user can open the file and read
    // it. Pretty == human-readable == what RGPD portability wants.
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(export),
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        title: 'Export Portea',
      ),
    );

    return path;
  }
}
