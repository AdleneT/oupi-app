import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oupi/domain/entities/parental_settings.dart';
import 'package:oupi/domain/entities/viewing_history.dart';
import 'package:oupi/domain/rules/parent_gate.dart';
import 'package:oupi/domain/rules/viewing_rules.dart';

import 'helpers.dart';

void main() {
  group('frenchNumber', () {
    test('écrit les nombres comme en France', () {
      expect(frenchNumber(21), 'vingt et un');
      expect(frenchNumber(47), 'quarante-sept');
      expect(frenchNumber(70), 'soixante-dix');
      expect(frenchNumber(71), 'soixante et onze');
      expect(frenchNumber(77), 'soixante-dix-sept');
      expect(frenchNumber(80), 'quatre-vingts');
      expect(frenchNumber(81), 'quatre-vingt-un');
      expect(frenchNumber(91), 'quatre-vingt-onze');
      expect(frenchNumber(99), 'quatre-vingt-dix-neuf');
    });

    test('refuse les nombres hors de 0 à 99', () {
      expect(() => frenchNumber(100), throwsRangeError);
    });
  });

  group('ParentGateChallenge', () {
    test('tire toujours un nombre à deux chiffres et accepte la bonne réponse', () {
      final random = Random(1);
      for (var i = 0; i < 200; i++) {
        final c = ParentGateChallenge.random(random);
        expect(c.target, inInclusiveRange(21, 99));
        expect(c.accepts(c.target.toString()), isTrue);
        expect(c.accepts('0${c.target % 10}'), isFalse);
      }
    });

    test('refuse une réponse incomplète ou fausse', () {
      final c = ParentGateChallenge(47);
      expect(c.question, 'quarante-sept');
      expect(c.accepts('4'), isFalse);
      expect(c.accepts('48'), isFalse);
      expect(c.accepts('47'), isTrue);
    });
  });

  group('Catalogue', () {
    test('10 épisodes, 5 gratuits et 5 abonnés, l’épisode 4 a ses interactions', () {
      final c = testCatalog();
      expect(c.episodes, hasLength(10));
      expect(c.episodes.where((e) => !e.premium), hasLength(5));
      final ep4 = c.byId('ep04')!;
      expect(ep4.title, 'Un cadeau pour Lolo');
      expect(ep4.activity.isDetailed, isTrue);
      expect(ep4.interactionsAsset, 'assets/data/interactions/ep04.json');
    });

    test('rangé par famille puis par numéro', () {
      final families = testCatalog().byFamily.map((e) => e.family).toList();
      expect(families, orderedEquals([...families]..sort((a, b) => a.compareTo(b) == 0 ? 0 : families.indexOf(a).compareTo(families.indexOf(b)))));
    });
  });

  group('ParentalSettings', () {
    test('borne la limite quotidienne entre 1 et 3', () {
      expect(const ParentalSettings(dailyLimit: 0).dailyLimit, 1);
      expect(const ParentalSettings(dailyLimit: 9).dailyLimit, 3);
      expect(ParentalSettings.defaults.copyWith(dailyLimit: 2).dailyLimit, 2);
    });

    test('dort de l’heure du dodo à 7 h', () {
      const s = ParentalSettings(sleepHour: 19);
      expect(s.isSleepTime(DateTime(2026, 11, 4, 18, 59)), isFalse);
      expect(s.isSleepTime(DateTime(2026, 11, 4, 19)), isTrue);
      expect(s.isSleepTime(DateTime(2026, 11, 5, 6, 30)), isTrue);
      expect(s.isSleepTime(DateTime(2026, 11, 5, 7)), isFalse);
    });
  });

  group('ViewingHistory', () {
    test('compte les lancements par jour et oublie au-delà de 30 jours', () {
      var h = ViewingHistory.empty.recordStart('ep01', DateTime(2026, 10, 1, 9));
      h = h.recordStart('ep02', DateTime(2026, 11, 4, 10));
      expect(h.startedOn(DateTime(2026, 11, 4)), 1);
      expect(h.startedOn(DateTime(2026, 10, 1)), 0, reason: 'plus de 30 jours : oublié');
    });

    test('est immuable', () {
      final h = ViewingHistory.empty;
      final next = h.markWatched('ep04');
      expect(h.hasWatched('ep04'), isFalse);
      expect(next.hasWatched('ep04'), isTrue);
      expect(identical(next.markWatched('ep04'), next), isTrue);
    });
  });

  group('ViewingRules', () {
    const rules = ViewingRules();
    final catalog = testCatalog();

    test('le verrou passe avant le dodo, qui passe avant la limite', () {
      final ep1 = catalog.byId('ep01')!;
      final ep6 = catalog.byId('ep06')!;
      final full = ViewingHistory.empty.recordStart('ep01', DateTime(2026, 11, 4, 20));
      const s = ParentalSettings();
      expect(rules.checkStart(ep6, s, full, DateTime(2026, 11, 4, 20)), StartCheck.locked);
      expect(rules.checkStart(ep1, s, full, DateTime(2026, 11, 4, 20)), StartCheck.sleepTime);
      expect(rules.checkStart(ep1, s, full, DateTime(2026, 11, 4, 10)), StartCheck.limitReached);
      expect(rules.checkStart(ep1, s, ViewingHistory.empty, DateTime(2026, 11, 4, 10)), StartCheck.ok);
      expect(rules.checkStart(ep6, s.copyWith(premium: true), ViewingHistory.empty, DateTime(2026, 11, 4, 10)), StartCheck.ok);
    });
  });
}
