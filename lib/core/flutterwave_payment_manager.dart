import 'dart:convert';
import 'dart:io';
import 'package:flutterwave/models/requests/authorization.dart';
import 'package:flutterwave/models/responses/charge_card_response/charge_card_response.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/cupertino.dart';
import 'package:flutterwave/models/requests/charge_card_request.dart';
import 'package:flutterwave/utils/flutterwave_utils.dart';

class FlutterwavePaymentManager {
  String publicKey;
  String encryptionKey;
  String currency;
  String amount;
  String email;
  String fullName;
  String txRef;
  String redirectUrl;
  bool isDebugMode;
  ChargeCardRequest chargeCardRequest;

  FlutterwavePaymentManager({
    @required this.publicKey,
    @required this.encryptionKey,
    @required this.currency,
    @required this.amount,
    @required this.email,
    @required this.fullName,
    @required this.txRef,
    @required this.isDebugMode,
    this.redirectUrl,
  });

  Map<String, String> _prepareRequest(
      final ChargeCardRequest chargeCardRequest) {
    final String encryptedChargeRequest = FlutterwaveUtils.TripleDESEncrypt(
        jsonEncode(chargeCardRequest.toJson()), encryptionKey);
    return FlutterwaveUtils.encryptRequest(encryptedChargeRequest);
  }

  Future<dynamic> payWithCard(final http.Client client,
      final ChargeCardRequest chargeCardRequest) async {
    print("Charge Request is ${chargeCardRequest.toJson()}");
    this.chargeCardRequest = chargeCardRequest;
    final Map<String, String> encryptedPayload =
        this._prepareRequest(chargeCardRequest);

    print("Encrypted Request is $encryptedPayload");

    final url = FlutterwaveUtils.BASE_URL + FlutterwaveUtils.CHARGE_CARD_URL;
    final http.Response response = await client.post(url,
        headers: {HttpHeaders.authorizationHeader: this.publicKey},
        body: encryptedPayload);
    try {
      print("Responssse code is ${jsonDecode(response.body)}");
      final responseBody =
          ChargeCardResponse.fromJson(jsonDecode(response.body));
      if (response.statusCode == 200 &&
          responseBody.meta != null &&
          responseBody.meta.authorization != null) {
        switch (responseBody.meta.authorization.mode) {
          case Authorization.AVS:
            {
              print("Authorization is Address Verification");
              print("Auth Body is ${responseBody.meta.authorization.toJson()}");
              break;
            }
          case Authorization.REDIRECT:
            {
              print("Authorization is Redirect");
              print("Auth Body is ${responseBody.meta.authorization.toJson()}");
              break;
            }
          case Authorization.OTP:
            {
              print("Authorization is OTP");
              print("Auth Body is ${responseBody.meta.authorization.toJson()}");
              break;
            }
          case Authorization.PIN:
            {
              print("Authorization is PIN");
              print("Auth Body is ${responseBody.meta.authorization.toJson()}");
              break;
            }
        }
        return;
      }
      print("Response code is ${response.statusCode}");
      print("Parsed response is ${responseBody.toJson()}");
      print("message is ${responseBody.message}");
//      print("Parsed response is ${responseBody.toJson()}");
    } catch (e) {
      print("Error is ${e.toString()}");
    }
  }
}