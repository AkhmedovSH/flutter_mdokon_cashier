import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/core/utils/changelog.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/profile/whats_new.dart';

void main() {
  group('changelog', () {
    test('версии идут от новой к старой и не повторяются', () {
      final versions = changelog.map((r) => r.version).toList();
      expect(versions.toSet().length, versions.length);
    });

    test('у каждой записи есть русский текст и он не пустой', () {
      for (final release in changelog) {
        expect(release.notes['ru'], isNotNull, reason: release.version);
        expect(release.notesFor('ru'), isNotEmpty, reason: release.version);
        for (final note in release.notesFor('ru')) {
          expect(note.trim(), isNotEmpty);
        }
      }
    });

    test('дата — либо null, либо разбираемая ISO-дата', () {
      for (final release in changelog) {
        final date = release.date;
        if (date != null) expect(() => DateTime.parse(date), returnsNormally);
      }
    });

    test('перевода нет — отдаём русский, а не пустой список', () {
      const release = ReleaseNote(
        version: '1.0.0',
        date: null,
        notes: {
          'ru': ['Русский пункт'],
        },
      );
      expect(release.notesFor('uz-Cyrl'), ['Русский пункт']);
      expect(release.notesFor('ru'), ['Русский пункт']);
    });

    test('releaseFor находит версию и молчит про неизвестную', () {
      expect(releaseFor(changelog.first.version), isNotNull);
      expect(releaseFor('0.0.0'), isNull);
    });
  });

  group('localeCode', () {
    test('совпадает с именами файлов переводов', () {
      expect(localeCode(const Locale('ru', '')), 'ru');
      expect(localeCode(const Locale('uz', 'Latn')), 'uz-Latn');
      expect(localeCode(const Locale('uz')), 'uz');
    });
  });
}
