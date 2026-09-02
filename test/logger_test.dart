import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/core/utils/logger.dart';

/// Логгер обязан быть тихим: он не бросает исключений, не теряет записи и
/// не тащит в файл персональные данные целиком.
void main() {
  late Directory dir;
  late AppLog log;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('mdokon-logs-');
    log = AppLog();
    await log.init(directory: dir);
  });

  tearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {
      // Windows держит файл — тест это не ломает.
    }
  });

  List<Map<String, dynamic>> readToday() {
    final file = log.fileFor();
    if (!file.existsSync()) return [];
    return file
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
  }

  test('запись уходит в дневной файл в формате JSONL', () {
    log.info('sale.started', {'chequeId': 12});
    log.flush();

    final entries = readToday();
    expect(entries.length, 1);
    expect(entries.first['event'], 'sale.started');
    expect(entries.first['level'], 'info');
    expect(entries.first['chequeId'], 12);
    expect(entries.first['ts'], isA<String>());
    expect(entries.first['sessionId'], log.sessionId);
  });

  test('имя файла — cashbox-ГГГГ-ММ-ДД.log', () {
    expect(log.dayKey(DateTime(2026, 3, 7)), '2026-03-07');
    expect(log.fileFor(DateTime(2026, 3, 7)).path, endsWith('cashbox-2026-03-07.log'));
  });

  test('error и audit пишутся сразу, info — по флашу', () {
    log.info('sale.item_added');
    expect(readToday(), isEmpty);

    log.audit('sale.item_deleted', {'name': 'Хлеб'});
    final entries = readToday();
    expect(entries.length, 2, reason: 'audit флашит и накопленный info');
    expect(entries.last['level'], 'audit');
  });

  test('debug молчит, пока выключен расширенный лог', () {
    // По умолчанию флаг выключен — подробности в файл не идут.
    expect(log.isVerbose, isFalse);
    log.debug('scan.raw', {'code': '0104607'});
    log.flush();
    expect(readToday(), isEmpty);
  });

  test('логгер не бросает на невалидном payload и режет длинные строки', () {
    final long = 'x' * (maxStringLength + 50);
    log.info('http.response', {'body': long, 'widget': Object()});
    log.flush();

    final entry = readToday().single;
    expect((entry['body'] as String).length, maxStringLength + 1, reason: 'обрезка + многоточие');
    expect(entry['widget'], isA<String>());
  });

  test('циклическая структура не роняет запись', () {
    final map = <String, dynamic>{};
    map['self'] = map;
    log.info('weird', {'payload': map});
    log.flush();

    expect(readToday().single['event'], 'weird');
  });

  test('logTail оставляет только хвост кода маркировки', () {
    expect(logTail('0104607428239631215uT1O2'), '…5uT1O2');
    expect(logTail('123'), '123');
    expect(logTail(null), '');
    expect(logTail('998901234567', keep: 4), '…4567');
  });

  test('exception сжимает ошибку до сообщения', () {
    log.exception('api.failed', Exception('boom'), {'url': '/sale'});

    final entry = readToday().single;
    expect(entry['level'], 'error');
    expect('${entry['message']}', contains('boom'));
    expect(entry['url'], '/sale');
  });

  test('контекст подставляется в каждую запись', () {
    log.setContext({'login': 'kassir1', 'cashboxId': 7});
    log.info('shift.opened');
    log.flush();

    final entry = readToday().single;
    expect(entry['login'], 'kassir1');
    expect(entry['cashboxId'], 7);
  });

  test('файлы старше 14 суток удаляются', () async {
    final old = log.fileFor(DateTime.now().subtract(const Duration(days: retentionDays + 1)));
    old.writeAsStringSync('{"event":"old"}\n');
    old.setLastModifiedSync(DateTime.now().subtract(const Duration(days: retentionDays + 1)));

    // Уборка идёт раз в сутки, и текущий экземпляр её уже отработал в init —
    // проверяем следующий запуск кассы над той же папкой.
    final restarted = AppLog();
    await restarted.init(directory: dir);

    expect(old.existsSync(), isFalse);
    expect(restarted.files(), isEmpty);
  });

  test('свежие файлы остаются', () {
    final yesterday = log.fileFor(DateTime.now().subtract(const Duration(days: 1)));
    yesterday.writeAsStringSync('{"event":"yesterday"}\n');

    log.info('today');
    log.flush();

    expect(yesterday.existsSync(), isTrue);
    expect(log.files().length, 2);
    expect(log.files().first.path, log.fileFor().path, reason: 'новые сверху');
  });

  test('export склеивает файлы в один и отдаёт путь', () async {
    final yesterday = log.fileFor(DateTime.now().subtract(const Duration(days: 1)));
    yesterday.writeAsStringSync('{"event":"yesterday"}\n');
    log.info('today');

    final path = await log.export();
    expect(path, isNotNull);
    final text = File(path!).readAsStringSync();
    expect(text, contains('yesterday'));
    expect(text, contains('today'));
  });

  test('export на пустой папке возвращает null', () async {
    expect(await log.export(), isNull);
  });

  test('clear удаляет файлы лога', () {
    log.info('sale.started');
    log.flush();
    expect(log.files(), isNotEmpty);

    log.clear();
    expect(log.files(), isEmpty);
  });

  test('без папки логгер работает вхолостую, а не падает', () {
    final orphan = AppLog();
    orphan.info('sale.started');
    orphan.flush();
    expect(orphan.files(), isEmpty);
  });

  test('переполнение буфера сбрасывает записи на диск без таймера', () {
    for (var i = 0; i < maxBuffer; i++) {
      log.info('scan', {'i': i});
    }
    expect(readToday().length, maxBuffer);
  });
}
