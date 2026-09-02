/// Лог кассы на устройстве.
///
/// Перенос десктопного `src/helpers/logger.js` + `public/logger.js`: у кассира
/// на точке никто не открывает консоль, а разбирать инцидент («почему чек ушёл
/// без скидки», «кто удалил позицию», «что ответил сервер») нужно постфактум и
/// часто офлайн. Поэтому события пишутся в файл, а не в `debugPrint`.
///
/// Правила те же, что на десктопе:
///   • логируем переходы состояния чека и внешние вызовы, а не «вход в каждую
///     функцию» — иначе в шуме ничего не найти;
///   • логгер никогда не бросает исключений и не тормозит продажу
///     (буфер + флаш пачкой);
///   • персональные данные (коды маркировки, телефоны) режем до хвоста
///     через [logTail].
///
/// Формат — JSONL (одна JSON-строка на событие): грепается, парсится, легко
/// отдать в поддержку. Файл на сутки, хранение [retentionDays] суток.
///
/// Уровни `error` / `warn` / `info` / `audit` пишутся всегда; `debug` — только
/// когда включён «Расширенный лог» ([kVerboseLogKey], device-local, как тема).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';


/// Ключ «Расширенного лога» в `GetStorage`.
const String kVerboseLogKey = 'verboseLog';

/// Сколько суток храним файлы.
const int retentionDays = 14;

/// Страховка от распухания за один день.
const int maxFileBytes = 25 * 1024 * 1024;

/// Как часто скидываем буфер на диск.
const Duration flushInterval = Duration(seconds: 2);

/// При переполнении буфера пишем сразу.
const int maxBuffer = 50;

/// Длинные строки в payload режем — лог должен оставаться читаемым.
const int maxStringLength = 300;

const String _filePrefix = 'cashbox-';
const String _fileSuffix = '.log';

/// Хвост строки для ПД: маркировку/телефон целиком в лог не кладём.
String logTail(Object? value, {int keep = 6}) {
  final s = '${value ?? ''}';
  if (s.length <= keep) return s;
  return '…${s.substring(s.length - keep)}';
}

/// Один пишущий на приложение.
final AppLog appLog = AppLog();

class AppLog {
  AppLog();

  /// Идентификатор запуска: связывает события одной сессии кассы.
  final String sessionId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  /// Общий контекст записи (кассир, точка, смена) — дополняет, а не заменяет.
  final Map<String, dynamic> _context = {};

  final List<Map<String, dynamic>> _buffer = [];
  Timer? _timer;
  Directory? _dir;
  String _lastCleanupDay = '';
  bool _globalsInstalled = false;

  /// Папка логов. Задаётся в [init]; в тестах передаётся напрямую.
  Directory? get directory => _dir;

  /// Подготовить папку логов. Вызывается один раз при старте; при передаче
  /// [directory] (тесты) сеть и платформенные каналы не трогаются.
  Future<void> init({Directory? directory}) async {
    try {
      final dir = directory ?? Directory('${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}logs');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      _dir = dir;
      cleanupOldFiles();
    } catch (_) {
      // Нет доступа к диску — касса работает, просто без файлового лога.
      _dir = null;
    }
  }

  /// Значение «Расширенного лога». Держим полем, а не читаем хранилище на
  /// каждый `debug`: при потоке сканов это сотни чтений в минуту, и в тестах
  /// (где `GetStorage` не инициализирован) обращение падало бы асинхронно.
  bool _verbose = false;

  bool get isVerbose => _verbose;

  /// Перечитать флаг из хранилища. Зовём после `GetStorage.init()` и после
  /// сохранения настроек.
  void refreshVerbose() {
    try {
      _verbose = GetStorage().read(kVerboseLogKey) == true;
    } catch (_) {
      _verbose = false;
    }
  }

  Future<void> setVerbose(bool on) async {
    _verbose = on;
    try {
      await GetStorage().write(kVerboseLogKey, on);
    } catch (_) {
      // Хранилище недоступно — не мешает работе.
    }
  }

  void setContext(Map<String, dynamic> patch) {
    _context.addAll(patch);
  }

  void info(String event, [Map<String, dynamic>? payload]) => _push('info', event, payload);

  void warn(String event, [Map<String, dynamic>? payload]) => _push('warn', event, payload);

  void error(String event, [Map<String, dynamic>? payload]) {
    _push('error', event, payload);
    flush();
  }

  /// Бизнес-событие: удаление позиции, ручная скидка, отмена чека — то, что
  /// читают люди, а не разработчик. Отдельный уровень, чтобы выбирать грепом.
  void audit(String event, [Map<String, dynamic>? payload]) {
    _push('audit', event, payload);
    flush();
  }

  void debug(String event, [Map<String, dynamic>? payload]) {
    if (isVerbose) _push('debug', event, payload);
  }

  /// Ошибка из `catch`: компактный вид (сообщение + http-статус), без стека
  /// целиком — стек в лог кассира не помещается и ничего ему не говорит.
  void exception(String event, Object? err, [Map<String, dynamic>? payload]) {
    error(event, {
      'message': _messageOf(err),
      if (_statusOf(err) != null) 'status': _statusOf(err),
      ...?payload,
    });
  }

  /// Глобальный перехват падений: сейчас такие ошибки не видит никто.
  /// Вызывается один раз при старте.
  void installGlobalErrorHandlers() {
    if (_globalsInstalled) return;
    _globalsInstalled = true;

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      error('app.flutter_error', {
        'message': '${details.exception}',
        'library': details.library ?? '',
      });
      previousOnError?.call(details);
    };

    PlatformDispatcher.instance.onError = (err, stack) {
      error('app.unhandled_error', {'message': _messageOf(err)});
      return false;
    };
  }

  void _push(String level, String event, Map<String, dynamic>? payload) {
    try {
      _buffer.add({
        'ts': DateTime.now().toIso8601String(),
        'level': level,
        'event': event,
        'sessionId': sessionId,
        ..._context,
        ..._clean(payload),
      });
      if (kDebugMode) debugPrint('[$level] $event ${payload ?? ''}');
      if (_buffer.length >= maxBuffer) {
        flush();
        return;
      }
      _timer ??= Timer(flushInterval, flush);
    } catch (_) {
      // Лог не должен ломать кассу.
    }
  }

  /// Payload приводим к тому, что переживёт `jsonEncode`: функции, виджеты и
  /// циклы роняют кодировщик, длинные строки режем.
  Map<String, dynamic> _clean(Map<String, dynamic>? payload) {
    if (payload == null || payload.isEmpty) return const {};
    final result = <String, dynamic>{};
    payload.forEach((key, value) {
      result[key] = _cleanValue(value, 0);
    });
    return result;
  }

  Object? _cleanValue(Object? value, int depth) {
    if (value == null || value is num || value is bool) return value;
    if (value is String) {
      return value.length > maxStringLength ? '${value.substring(0, maxStringLength)}…' : value;
    }
    if (depth >= 4) return '$value';
    if (value is Map) {
      return value.map((k, v) => MapEntry('$k', _cleanValue(v, depth + 1)));
    }
    if (value is Iterable) {
      return value.map((v) => _cleanValue(v, depth + 1)).toList();
    }
    return _cleanValue('$value', depth);
  }

  String _messageOf(Object? err) {
    if (err == null) return '';
    try {
      final dynamic e = err;
      final dynamic message = e.message;
      if (message != null) return '$message';
    } catch (_) {
      // Не Dio/Exception — берём toString ниже.
    }
    return '$err';
  }

  int? _statusOf(Object? err) {
    try {
      final dynamic status = (err as dynamic).response?.statusCode;
      if (status is int) return status;
    } catch (_) {
      // Ошибка не от Dio.
    }
    return null;
  }

  /// Записать буфер на диск. Безопасно вызывать когда угодно.
  void flush() {
    _timer?.cancel();
    _timer = null;
    if (_buffer.isEmpty) return;

    final chunk = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();

    final dir = _dir;
    if (dir == null) return;

    cleanupOldFiles();
    try {
      final file = fileFor();
      if (file.existsSync() && file.lengthSync() > maxFileBytes) return; // дневной лимит исчерпан
      final text = '${chunk.map(_serialize).join('\n')}\n';
      file.writeAsStringSync(text, mode: FileMode.append, flush: true);
    } catch (_) {
      // Диск занят/переполнен — лог не должен ломать кассу.
    }
  }

  String _serialize(Map<String, dynamic> entry) {
    try {
      return jsonEncode(entry);
    } catch (_) {
      return jsonEncode({
        'ts': entry['ts'] ?? DateTime.now().toIso8601String(),
        'level': 'error',
        'event': 'log.serialize_failed',
      });
    }
  }

  String dayKey([DateTime? date]) {
    final d = date ?? DateTime.now();
    final m = '${d.month}'.padLeft(2, '0');
    final day = '${d.day}'.padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  File fileFor([DateTime? date]) {
    final dir = _dir!;
    return File('${dir.path}${Platform.pathSeparator}$_filePrefix${dayKey(date)}$_fileSuffix');
  }

  /// Файлы лога, новые сверху.
  List<File> files() {
    final dir = _dir;
    if (dir == null || !dir.existsSync()) return const [];
    try {
      final list = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.uri.pathSegments.last.startsWith(_filePrefix))
          .toList();
      list.sort((a, b) => b.path.compareTo(a.path));
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// Удаляем файлы старше [retentionDays]. Дёргается при старте и при флаше;
  /// реально работает раз в сутки.
  void cleanupOldFiles() {
    final dir = _dir;
    if (dir == null) return;
    final today = dayKey();
    if (_lastCleanupDay == today) return;
    _lastCleanupDay = today;

    final edge = DateTime.now().subtract(const Duration(days: retentionDays));
    for (final file in files()) {
      try {
        if (file.lastModifiedSync().isBefore(edge)) file.deleteSync();
      } catch (_) {
        // Файл занят/уже удалён — не мешает работе.
      }
    }
  }

  /// Собрать все файлы в один — его отдают в поддержку. Возвращает путь.
  Future<String?> export() async {
    flush();
    final dir = _dir;
    if (dir == null) return null;
    final sources = files().reversed.toList();
    if (sources.isEmpty) return null;
    try {
      final out = File('${dir.path}${Platform.pathSeparator}export-${dayKey()}$_fileSuffix');
      final sink = StringBuffer();
      for (final file in sources) {
        if (file.path == out.path) continue;
        sink.writeln('# ${file.uri.pathSegments.last}');
        sink.write(file.readAsStringSync());
      }
      out.writeAsStringSync(sink.toString(), flush: true);
      return out.path;
    } catch (_) {
      return null;
    }
  }

  /// Удалить все файлы лога.
  void clear() {
    _buffer.clear();
    for (final file in files()) {
      try {
        file.deleteSync();
      } catch (_) {
        // Занят — попробуем в следующий раз.
      }
    }
  }
}
