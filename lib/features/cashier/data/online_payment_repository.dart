import 'package:dio/dio.dart';

import 'package:flutter_mdokon/features/cashier/domain/online_payment.dart';

/// Прямые HTTP-запросы к Click Pass / Payme / Uzum — порт `apiClick.js`,
/// `apiPayme.js`, `apiUzum.js`.
///
/// Идут мимо `core/network/api.dart`: это чужие хосты со своей авторизацией,
/// токен кабинета им не нужен и слать его туда нельзя.
///
/// В отличие от маркировки, мягкой деградации тут нет: не прошла оплата —
/// чек не пробивается. Ошибка возвращается кассиру текстом провайдера.
const _clickUrl = 'https://api.click.uz/v2/merchant/click_pass/payment';
const _paymeUrl = 'https://checkout.paycom.uz/api/merchant/payment';
const _uzumUrl = 'https://mobile.apelsin.uz/api/apelsin-pay/merchant/payment';

class OnlinePaymentRepository {
  OnlinePaymentRepository({Dio? client})
      : _dio = client ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
              headers: const {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              // Ошибку провайдера разбираем сами: у Click и Payme осмысленный
              // текст лежит в теле даже при 4xx.
              validateStatus: (_) => true,
            ));

  final Dio _dio;

  Future<dynamic> _post(String url, Map<String, dynamic> data, Map<String, String> headers) async {
    final response = await _dio.post(url, data: data, options: Options(headers: headers));
    return response.data;
  }

  /// Click Pass: один запрос, `otp_data` — код с телефона покупателя.
  Future<OnlinePaymentResult> payClick({
    required Map<String, dynamic> payload,
    required String auth,
  }) async {
    try {
      final response = await _post(_clickUrl, payload, {'Authorization': auth, 'auth': auth});
      return parseClickResponse(response);
    } catch (e) {
      return OnlinePaymentResult(ok: false, error: '$e');
    }
  }

  /// Uzum (Apelsin): один запрос.
  Future<OnlinePaymentResult> payUzum({
    required Map<String, dynamic> payload,
    required String auth,
  }) async {
    try {
      final response = await _post(_uzumUrl, payload, {'Authorization': auth});
      return parseUzumResponse(response);
    } catch (e) {
      return OnlinePaymentResult(ok: false, error: '$e');
    }
  }

  /// Payme: два шага — `receipts.create`, затем `receipts.pay` по его `_id`.
  Future<OnlinePaymentResult> payPayme({
    required Map<String, dynamic> createPayload,
    required String otpCode,
    required String auth,
  }) async {
    try {
      final headers = {'Authorization': auth, 'X-AUTH': auth};
      final created = await _post(_paymeUrl, createPayload, headers);

      final createError = parsePaymeResponse(created);
      if (!createError.ok) return createError;

      final receiptId = paymeReceiptId(created);
      if (receiptId == null) {
        return const OnlinePaymentResult(ok: false);
      }

      final response = await _post(
        _paymeUrl,
        paymePayPayload(
          requestId: created is Map ? created['id'] : createPayload['id'],
          receiptId: receiptId,
          otpCode: otpCode,
        ),
        headers,
      );
      return parsePaymeResponse(response);
    } catch (e) {
      return OnlinePaymentResult(ok: false, error: '$e');
    }
  }
}
