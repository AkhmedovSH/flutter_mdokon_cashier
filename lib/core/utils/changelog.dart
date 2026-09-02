/// История обновлений приложения — источник экрана «Что нового».
///
/// Пополняется ВРУЧНУЮ при каждом релизе: новая версия добавляется В НАЧАЛО
/// [changelog]. Формат повторяет десктопный `src/data/changelog.js`, чтобы
/// записи можно было переносить между кассами без переписывания.
///
/// `date` — `null`, если версия ещё не вышла в маркет.
/// `notes` — тексты по языкам интерфейса; ключи совпадают с кодами локалей
/// (`ru`, `uz-Latn`, `uz-Cyrl`). Локали `uz-Cyrl` пока нет в приложении, но
/// ключ зарезервирован: когда третий язык появится, экран подхватит его сам.
library;

class ReleaseNote {
  final String version;
  final String? date;
  final Map<String, List<String>> notes;

  const ReleaseNote({
    required this.version,
    required this.date,
    required this.notes,
  });

  /// Заметки на нужном языке. Если перевода нет — русский, он заполнен всегда.
  List<String> notesFor(String localeCode) =>
      notes[localeCode] ?? notes['ru'] ?? const [];
}

const List<ReleaseNote> changelog = [
  ReleaseNote(
    version: '2.1.0',
    date: null,
    notes: {
      'ru': [
        'Тёмная тема — приложение целиком переключается между светлым и тёмным оформлением, режим выбирается в настройках и запоминается на устройстве',
        'Планшет — на широком экране касса работает в две колонки: чек всегда виден рядом с каталогом, чеки и возвраты открываются списком с карточкой справа, а разделы переезжают в верхнюю навигацию',
        'Касса — несколько чеков одновременно: вкладки чеков позволяют отложить обслуживание одного покупателя и вернуться к нему, ничего не теряя',
        'Касса — боковая колонка быстрого выбора: список, витрина, категории и цифровая клавиатура под рукой',
        'Касса — быстрый ввод: «2+» количество, «2000*» цена, «5000-» сумма, «/» упаковка; подсказка по вводу открывается прямо из кассы',
        'Маркировка — код DataMatrix сканируется камерой прямо в продаже: касса узнаёт код, проверяет его и добавляет товар в чек с уже подставленным кодом. Проверка только предупреждает и никогда не блокирует продажу. Возврат по коду маркировки тоже поддержан',
        'Оплата — Click Pass, Payme и Uzum доступны не только во вкладке «Оплата», но и в долге и лояльности. Абонплату теперь можно оплатить картой прямо из кассы',
        'Отложенные чеки — чек откладывается на устройстве или в облаке (выбирается в настройках) и открывается обратно в один тап. Добавлен взаиморасчёт с поставщиками',
        'Лояльность — подключена UDS',
        'Скидки — ручная скидка и акции пересчитываются так же, как в десктопной кассе: скидка больше не «едет» при изменении количества',
        'Настройки — раздел переписан: подтверждения удаления, группировка товаров, точный поиск, формат весового штрих-кода и префиксы, печать штрих-кода и QR, печать чека возврата и два чека, режим отложенных чеков',
      ],
      'uz-Latn': [
        "Tungi mavzu — ilova to'liq yorug' va qorong'i ko'rinish orasida almashadi, rejim sozlamalarda tanlanadi va qurilmada saqlanadi",
        "Planshet — keng ekranda kassa ikki ustunda ishlaydi: chek doimo katalog yonida ko'rinadi, cheklar va qaytarishlar ro'yxat va o'ngdagi karta ko'rinishida ochiladi, bo'limlar esa yuqori navigatsiyaga ko'chadi",
        "Kassa — bir vaqtda bir nechta chek: chek varaqlari bir xaridorni kutishga qo'yib, keyin hech narsa yo'qotmay qaytishga imkon beradi",
        "Kassa — tezkor tanlash ustuni: ro'yxat, vitrina, kategoriyalar va raqamli klaviatura qo'l ostida",
        "Kassa — tezkor kiritish: «2+» miqdor, «2000*» narx, «5000-» summa, «/» qadoq; kiritish bo'yicha eslatma kassaning o'zidan ochiladi",
        "Markirovka — DataMatrix kodi sotuvning o'zida kamera bilan skanerlanadi: kassa kodni taniydi, tekshiradi va tovarni kodi bilan birga chekka qo'shadi. Tekshiruv faqat ogohlantiradi va hech qachon sotuvni to'xtatmaydi. Markirovka kodi bo'yicha qaytarish ham qo'llab-quvvatlanadi",
        "To'lov — Click Pass, Payme va Uzum endi faqat «To'lov» bo'limida emas, qarz va sadoqat bo'limlarida ham mavjud. Abonent to'lovini kassadan karta bilan to'lash mumkin",
        "Kechiktirilgan cheklar — chek qurilmada yoki bulutda kechiktiriladi (sozlamalarda tanlanadi) va bir tegishda qaytib ochiladi. Yetkazib beruvchilar bilan o'zaro hisob-kitob qo'shildi",
        'Sadoqat — UDS ulandi',
        "Chegirmalar — qo'lda chegirma va aksiyalar desktop kassadagidek qayta hisoblanadi: miqdor o'zgarganda chegirma endi «siljib» ketmaydi",
        "Sozlamalar — bo'lim qayta yozildi: o'chirishni tasdiqlash, tovarlarni guruhlash, aniq qidiruv, tarozi shtrix-kod formati va prefikslar, shtrix-kod va QR chop etish, qaytarish chekini va ikkita chekni chop etish, kechiktirilgan cheklar rejimi",
      ],
    },
  ),
];

/// Запись для конкретной версии приложения, если она описана.
ReleaseNote? releaseFor(String version) {
  for (final release in changelog) {
    if (release.version == version) return release;
  }
  return null;
}
