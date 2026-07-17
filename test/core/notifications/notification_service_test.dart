import 'package:flutter_test/flutter_test.dart';
import 'package:portea_flutter/core/notifications/inotification_service.dart';

void main() {
  group('parseNotificationPayload (deep-link routing)', () {
    test('individual care route → puppy file', () {
      expect(parseNotificationPayload('/puppies/42'), '/puppies/42');
    });

    test('group care route → litter detail', () {
      expect(parseNotificationPayload('/litters/7'), '/litters/7');
    });

    test('null payload → dashboard, never crashes', () {
      expect(parseNotificationPayload(null), '/dashboard');
    });

    test('empty payload → dashboard', () {
      expect(parseNotificationPayload(''), '/dashboard');
    });

    test('garbage payload → dashboard', () {
      expect(parseNotificationPayload('not-a-route'), '/dashboard');
    });

    test('route with non-numeric id → dashboard', () {
      expect(parseNotificationPayload('/puppies/abc'), '/dashboard');
    });

    test('route with extra path segments → dashboard', () {
      expect(parseNotificationPayload('/puppies/1/extra'), '/dashboard');
    });
  });

  group('reminderTitle (F07 rule 7 — target name)', () {
    test('individual care → "Rappel soin — {puppyName}"', () {
      expect(
        reminderTitle(puppyName: 'Orphée'),
        'Rappel soin — Orphée',
      );
    });

    test('group care → "Rappel soin — Portée de {motherName}"', () {
      expect(
        reminderTitle(motherName: 'Salsa'),
        'Rappel soin — Portée de Salsa',
      );
    });

    test('no name available → degraded "Rappel soin"', () {
      expect(reminderTitle(), 'Rappel soin');
      expect(reminderTitle(puppyName: ''), 'Rappel soin');
      expect(reminderTitle(motherName: '   '), 'Rappel soin');
    });
  });

  group('reminderBody (F07 rule 7 — type and product)', () {
    test('vaccine with product → "Vaccin — {produit}"', () {
      expect(
        reminderBody(type: 'vaccine', product: 'CHPPIL'),
        'Vaccin — CHPPIL',
      );
    });

    test('deworming with product → "Vermifuge — {produit}"', () {
      expect(
        reminderBody(type: 'deworming', product: 'Milbemax'),
        'Vermifuge — Milbemax',
      );
    });

    test('unknown type → "Soin — {produit}"', () {
      expect(
        reminderBody(type: 'other', product: 'Doliprane'),
        'Soin — Doliprane',
      );
    });

    test('null product → type only (product omitted)', () {
      expect(reminderBody(type: 'vaccine', product: null), 'Vaccin');
    });

    test('blank product → type only (product omitted)', () {
      expect(reminderBody(type: 'deworming', product: '  '), 'Vermifuge');
    });
  });
}
