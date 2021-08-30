import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import 'package:meta/meta.dart';
import 'package:stripe_app/models/payment_intent_response.dart';
import 'package:stripe_app/models/stripe_custom_response.dart';

import 'package:stripe_payment/stripe_payment.dart';

class StripeService {
  // Singleton
  StripeService._privateConstructor();
  static final StripeService _intance = StripeService._privateConstructor();
  factory StripeService() => _intance;

  String _paymentApiUrl = 'https://api.stripe.com/v1/payment_intents';

  static String _secretKey =
      'sk_test_51JTuirFH57TYN8a8nKJmMMN74MyVr9d8aF0Hl2b617yr0mmIxhIwckJAeQCjnxBCeg5Sytq1zgp39Qz3NmZpe8U600IEJdqz6l';

  String _apiKey =
      'pk_test_51JTuirFH57TYN8a8B2pEbTmZp7kbL2HRGoAhyS7EBmhdbp2ZgDassMCpYZtMjQwZfvZtyXW8wTcmgKb5sOxmoXro00SDe6lxw7';

  final headerOptions = new Options(
      contentType: Headers.formUrlEncodedContentType,
      headers: {'Authorization': 'Bearer ${StripeService._secretKey}'});

  void init() {
    StripePayment.setOptions(StripeOptions(
        publishableKey: this._apiKey,
        androidPayMode: 'test',
        merchantId: 'test'));
  }

  Future<StripeCustomResponse> pagarConTarjetaExiste({
    required String amount,
    required String currency,
    required CreditCard card,
  }) async {
    try {
      final paymentMethod = await StripePayment.createPaymentMethod(
          PaymentMethodRequest(card: card));

      final resp = await this._realizarPago(
          amount: amount, currency: currency, paymentMethod: paymentMethod);

      return resp;
    } catch (e) {
      return StripeCustomResponse(ok: false, msg: e.toString());
    }
  }

  Future<StripeCustomResponse> pagarConNuevaTarjeta({
    required String amount,
    required String currency,
  }) async {
    try {
      final paymentMethod = await StripePayment.paymentRequestWithCardForm(
          CardFormPaymentRequest());

      //return StripeCustomResponse(ok: true);

      final resp = await this._realizarPago(
          amount: amount, currency: currency, paymentMethod: paymentMethod);

      return resp;
    } catch (e) {
      return StripeCustomResponse(ok: false, msg: e.toString());
    }
  }

  Future<StripeCustomResponse> pagarApplePayGooglePay({
    required String amount,
    required String currency,
  }) async {
    try {
      final newAmount = double.parse(amount) / 100;

      final token = await StripePayment.paymentRequestWithNativePay(
          androidPayOptions: AndroidPayPaymentRequest(
            totalPrice: amount,
            currencyCode: currency,
          ),
          applePayOptions: ApplePayPaymentOptions(
              countryCode: 'US',
              currencyCode: currency,
              items: [
                ApplePayItem(label: 'Super producto 1', amount: '$newAmount')
              ]));

      final paymentMethod = await StripePayment.createPaymentMethod(
          PaymentMethodRequest(card: CreditCard(token: token.tokenId)));

      final resp = await this._realizarPago(
          amount: amount, currency: currency, paymentMethod: paymentMethod);

      await StripePayment.completeNativePayRequest();

      return resp;
    } catch (e) {
      print('Error en intento: ${e.toString()}');
      return StripeCustomResponse(ok: false, msg: e.toString());
    }
  }

  Future<PaymentIntentResponse> _crearPaymentIntent({
    required String amount,
    required String currency,
  }) async {
    try {
      final dio = new Dio();
      final data = {'amount': amount, 'currency': currency};

      final resp =
          await dio.post(_paymentApiUrl, data: data, options: headerOptions);

      return PaymentIntentResponse.fromJson(resp.data);
    } catch (e) {
      print('Error en intento: ${e.toString()}');
      return PaymentIntentResponse(
        status: json.decode('400'),
        id: json.decode("id"),
        object: json.decode("object"),
        amount: json.decode("amount"),
        amountCapturable: json.decode("amount_capturable"),
        amountReceived: json.decode("amount_received"),
        application: json.decode("application"),
        applicationFeeAmount: json.decode("application_fee_amount"),
        canceledAt: json.decode("canceled_at"),
        cancellationReason: json.decode("cancellation_reason"),
        captureMethod: json.decode("capture_method"),
        charges: Charges.fromJson(json.decode("charges")),
        clientSecret: json.decode("client_secret"),
        confirmationMethod: json.decode("confirmation_method"),
        created: json.decode("created"),
        currency: json.decode("currency"),
        customer: json.decode("customer"),
        description: json.decode("description"),
        invoice: json.decode("invoice"),
        lastPaymentError: json.decode("last_payment_error"),
        livemode: json.decode("livemode"),
        metadata: Metadata.fromJson(json.decode("metadata")),
        nextAction: json.decode("next_action"),
        onBehalfOf: json.decode("on_behalf_of"),
        paymentMethod: json.decode("payment_method"),
        paymentMethodOptions: PaymentMethodOptions.fromJson(
            json.decode("payment_method_options")),
        paymentMethodTypes: List<String>.from(
            json.decode("payment_method_types").map((x) => x)),
        receiptEmail: json.decode("receipt_email"),
        review: json.decode("review"),
        setupFutureUsage: json.decode("setup_future_usage"),
        shipping: json.decode("shipping"),
        source: json.decode("source"),
        statementDescriptor: json.decode("statement_descriptor"),
        statementDescriptorSuffix: json.decode("statement_descriptor_suffix"),
        transferData: json.decode("transfer_data"),
        transferGroup: json.decode("transfer_group"),
      );
    }
  }

  Future _realizarPago(
      {required String amount,
      required String currency,
      required PaymentMethod paymentMethod}) async {
    try {
      // Crear el intent
      final paymentIntent =
          await this._crearPaymentIntent(amount: amount, currency: currency);

      final paymentResult = await StripePayment.confirmPaymentIntent(
          PaymentIntent(
              clientSecret: paymentIntent.clientSecret,
              paymentMethodId: paymentMethod.id));

      if (paymentResult.status == 'succeeded') {
        return StripeCustomResponse(ok: true);
      } else {
        return StripeCustomResponse(
            ok: false, msg: 'Fallo: ${paymentResult.status}');
      }
    } catch (e) {
      print(e.toString());
      return StripeCustomResponse(ok: false, msg: e.toString());
    }
  }
}
