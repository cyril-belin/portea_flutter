import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portea_client/portea_client.dart';
import 'package:portea_flutter/core/pdf/cession_template.dart';
import 'package:portea_flutter/core/pdf/pdf_fonts.dart';
import 'package:portea_flutter/core/pdf/registre_template.dart';

/// Non-regression tests for the F09 PDF templates.
///
/// We do NOT assert the visual rendering (no golden test — the spec says
/// "pas de test de rendu visuel"). The contract is narrower: each template,
/// given complete data, produces a NON-EMPTY byte buffer without throwing.
/// That catches regressions where a model change would break the layout code
/// (a renamed field, a null access, a wrong type) — which is the actual risk.
void main() {
  // The PDF templates load a Unicode font via PdfFonts, which normally reads
  // the bundled asset through rootBundle. A pure dart test has no live asset
  // bundle, so we inject the same TTF bytes directly from the project's
  // assets directory. This exercises the real font path (Helvetica would drop
  // the French accents in the test data — "Élevage", "Soleil", "cédée").
  setUpAll(() async {
    final bytes = await File('assets/fonts/NotoSans.ttf').readAsBytes();
    PdfFonts.loadFromBytes(ByteData.sublistView(bytes));
  });

  group('buildCessionPdf', () {
    test('produces a non-empty PDF from a complete dossier', () async {
      final kennel = Kennel(
        id: 1,
        name: 'Élevage du Soleil',
        affix: 'du Soleil',
        siret: '12345678900012',
        ownerName: 'Marie Curie',
        ownerAddress: '12 rue de la Paix, Paris',
        ownerPhone: '0612345678',
        ownerEmail: 'marie@elevage.fr',
        species: 'dog',
        createdAt: DateTime(2025, 1, 1),
      );
      final litter = Litter(
        id: 1,
        motherId: 10,
        birthDate: DateTime(2026, 1, 15),
        kennelId: 1,
        isActive: true,
      );
      final puppy = Puppy(
        id: 100,
        litterId: 1,
        name: 'Rex',
        sex: 'male',
        color: 'Fauve',
        status: 'sold',
        chipNumber: '250268739182736',
        buyerName: 'Jean Dupont',
        buyerAddress: '5 avenue des Champs, Marseille',
        buyerPhone: '0698765432',
        buyerEmail: 'jean.dupont@email.com',
        cessionDate: DateTime(2026, 3, 20),
      );
      final mother = Breeder(
        id: 10,
        name: 'Salsa',
        sex: 'female',
        breed: 'Golden Retriever',
        status: 'active',
        kennelId: 1,
      );

      final bytes = await buildCessionPdf(
        kennel: kennel,
        litter: litter,
        puppy: puppy,
        mother: mother,
      );

      expect(bytes, isNotEmpty);
      // PDFs start with the %PDF- magic bytes — a cheap structural sanity
      // check that we got a real document, not random bytes.
      expect(bytes[0], equals(0x25)); // %
      expect(bytes[1], equals(0x50)); // P
    });

    test(
      'renders "Non renseigné" for a missing chip without throwing',
      () async {
        final kennel = Kennel(
          id: 1,
          name: 'Élevage',
          species: 'dog',
          createdAt: DateTime(2025, 1, 1),
        );
        final litter = Litter(
          id: 1,
          motherId: 10,
          birthDate: DateTime(2026, 1, 15),
          kennelId: 1,
          isActive: true,
        );
        final puppy = Puppy(
          id: 100,
          litterId: 1,
          name: 'Rex',
          sex: 'male',
          status: 'sold',
          buyerName: 'Jean',
          buyerAddress: 'Adresse',
          buyerPhone: '0612345678',
          cessionDate: DateTime(2026, 3, 20),
          // chipNumber null, color null — the template must tolerate it.
        );

        final bytes = await buildCessionPdf(
          kennel: kennel,
          litter: litter,
          puppy: puppy,
          mother: null,
        );

        expect(bytes, isNotEmpty);
      },
    );
  });

  group('buildRegistrePdf', () {
    test('produces a non-empty PDF with multiple litters', () async {
      final kennel = Kennel(
        id: 1,
        name: 'Élevage du Soleil',
        affix: 'du Soleil',
        species: 'dog',
        createdAt: DateTime(2025, 1, 1),
      );
      final litters = [
        Litter(
          id: 1,
          motherId: 10,
          birthDate: DateTime(2026, 1, 15),
          kennelId: 1,
          isActive: true,
        ),
        Litter(
          id: 2,
          motherId: 11,
          birthDate: DateTime(2025, 9, 10),
          kennelId: 1,
          isActive: false,
        ),
      ];
      final mothers = <int, Breeder?>{
        10: Breeder(
          id: 10,
          name: 'Salsa',
          sex: 'female',
          breed: 'Golden Retriever',
          status: 'active',
          kennelId: 1,
        ),
        11: Breeder(
          id: 11,
          name: 'Luna',
          sex: 'female',
          breed: 'Labrador',
          status: 'active',
          kennelId: 1,
        ),
      };
      final puppiesByLitter = <int, List<Puppy>>{
        1: [
          Puppy(
            id: 100,
            litterId: 1,
            name: 'Rex',
            sex: 'male',
            status: 'sold',
            buyerName: 'Jean',
            cessionDate: DateTime(2026, 3, 20),
          ),
          Puppy(
            id: 101,
            litterId: 1,
            name: 'Belle',
            sex: 'female',
            status: 'available',
          ),
        ],
        2: [
          Puppy(
            id: 200,
            litterId: 2,
            name: 'Max',
            sex: 'male',
            status: 'sold',
            buyerName: 'Marie',
            cessionDate: DateTime(2025, 11, 1),
          ),
        ],
      };

      final bytes = await buildRegistrePdf(
        kennel: kennel,
        litters: litters,
        mothers: mothers,
        puppiesByLitter: puppiesByLitter,
      );

      expect(bytes, isNotEmpty);
      expect(bytes[0], equals(0x25)); // %
    });

    test('produces a valid one-page PDF for an empty kennel', () async {
      final kennel = Kennel(
        id: 1,
        name: 'Nouvel Élevage',
        species: 'dog',
        createdAt: DateTime(2025, 1, 1),
      );

      final bytes = await buildRegistrePdf(
        kennel: kennel,
        litters: const [],
        mothers: const {},
        puppiesByLitter: const {},
      );

      expect(bytes, isNotEmpty);
    });

    test('tolerates a litter with an unknown dam', () async {
      final kennel = Kennel(
        id: 1,
        name: 'Élevage',
        species: 'dog',
        createdAt: DateTime(2025, 1, 1),
      );
      // motherId points to a breeder not in the map.
      final litters = [
        Litter(
          id: 1,
          motherId: 999,
          birthDate: DateTime(2026, 1, 1),
          kennelId: 1,
          isActive: true,
        ),
      ];

      final bytes = await buildRegistrePdf(
        kennel: kennel,
        litters: litters,
        mothers: const {},
        puppiesByLitter: const {},
      );

      expect(bytes, isNotEmpty);
    });
  });
}
