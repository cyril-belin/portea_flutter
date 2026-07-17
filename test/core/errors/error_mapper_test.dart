import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portea_client/portea_client.dart';
import 'package:portea_flutter/core/errors/error_mapper.dart';

void main() {
  group('mapExceptionToMessage — typed business exceptions', () {
    // Each typed exception surfaces its server-authored French message verbatim
    // (the .spy.yaml default). A custom message passed at throw time is also
    // honored.
    test('InvalidLitterRelationException surfaces its server message', () {
      expect(
        mapExceptionToMessage(InvalidLitterRelationException()),
        equals(
          'La mère ou le père déclaré n\'est pas valide pour ce kennel.',
        ),
      );
    });

    test('InvalidPuppyRelationException surfaces its server message', () {
      expect(
        mapExceptionToMessage(InvalidPuppyRelationException()),
        equals(
          'Le chiot déclaré n\'appartient pas à cette portée ou est introuvable.',
        ),
      );
    });

    test('PuppyDeletionNotAllowedException surfaces its server message', () {
      // This is the F05 smoke-test wording: deleting a puppy with a weighing
      // history must reach the user as a business sentence, not a generic error.
      expect(
        mapExceptionToMessage(PuppyDeletionNotAllowedException()),
        contains('historique'),
      );
    });

    test('InvalidWeighingRelationException surfaces its server message', () {
      expect(
        mapExceptionToMessage(InvalidWeighingRelationException()),
        contains('pesée'),
      );
    });

    test('InvalidWeighingInputException surfaces its server message', () {
      expect(
        mapExceptionToMessage(InvalidWeighingInputException()),
        contains('poids'),
      );
    });

    test('a custom message provided at throw time is honored', () {
      expect(
        mapExceptionToMessage(
          InvalidLitterRelationException(
            message: 'Mauvaise mère: sexe incorrect',
          ),
        ),
        equals('Mauvaise mère: sexe incorrect'),
      );
    });
  });

  group('mapExceptionToMessage — ActiveLitterLimitException is NOT mapped', () {
    // Documented contract: this exception is a paywall signal handled by the
    // view model, never a user-facing string. The mapper must therefore fall
    // through to the generic message if it ever receives one — this test pins
    // that behavior so a future "helpful" addition does not silently turn the
    // paywall into a SnackBar.
    test('falls through to the generic message (paywall handled upstream)', () {
      expect(
        mapExceptionToMessage(ActiveLitterLimitException()),
        equals('Une erreur est survenue. Veuillez réessayer.'),
      );
    });
  });

  group('mapExceptionToMessage — transport / HTTP layer', () {
    test('statusCode -1 (unreachable) → network message', () {
      expect(
        mapExceptionToMessage(
          const ServerpodClientException('Connection refused', -1),
        ),
        equals('Vérifiez votre connexion internet.'),
      );
    });

    test('401 (ServerpodClientUnauthorized) → session-expired message', () {
      expect(
        mapExceptionToMessage(ServerpodClientUnauthorized()),
        equals('Votre session a expiré. Reconnectez-vous pour continuer.'),
      );
    });

    test('403 → forbidden message', () {
      expect(
        mapExceptionToMessage(
          const ServerpodClientException('Forbidden', 403),
        ),
        equals("Vous n'avez pas accès à cette action."),
      );
    });

    test('500 and other status codes → generic message', () {
      expect(
        mapExceptionToMessage(
          const ServerpodClientException('Internal Server Error', 500),
        ),
        equals('Une erreur est survenue. Veuillez réessayer.'),
      );
      expect(
        mapExceptionToMessage(
          const ServerpodClientException('Bad Request', 400),
        ),
        equals('Une erreur est survenue. Veuillez réessayer.'),
      );
    });
  });

  group('mapExceptionToMessage — raw network primitives', () {
    // The Serverpod IO delegate normally wraps these into statusCode -1, but
    // the mapper stays correct for any code path that bypasses it.
    test('TimeoutException → timeout message', () {
      expect(
        mapExceptionToMessage(
          TimeoutException('request', const Duration(seconds: 5)),
        ),
        contains('connexion'),
      );
    });

    test('SocketException → network message', () {
      expect(
        mapExceptionToMessage(const SocketException('Connection failed')),
        equals('Vérifiez votre connexion internet.'),
      );
    });
  });

  group('mapExceptionToMessage — fallback', () {
    test('a bare Exception → generic message', () {
      expect(
        mapExceptionToMessage(Exception('boom')),
        equals('Une erreur est survenue. Veuillez réessayer.'),
      );
    });

    test('a String thrown → generic message', () {
      expect(
        mapExceptionToMessage('something weird'),
        equals('Une erreur est survenue. Veuillez réessayer.'),
      );
    });
  });
}
