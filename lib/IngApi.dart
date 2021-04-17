import 'dart:convert';
import 'package:http/http.dart' as http;

import 'my_inbox.dart';

class IngApi {
  static String domain = "192.168.1.83:8080";

  static Future<dynamic> getAccounts() async {
    return jsonDecode((await http.get(Uri.http(domain, "accounts"))).body);
  }

  static Future<dynamic> getAccountBankRecord(String accountId) async {
    return jsonDecode((await http.get(Uri.http(domain, "account/$accountId/bankRecord"))).body);
  }

  static Future<dynamic> getBeneficiaries(String accountId) async {
    return jsonDecode((await http.get(Uri.http(domain, "account/$accountId/externalAccount"))).body);
  }

  static Future<dynamic> getAccountById(String accountId) async {
    return jsonDecode((await http.get(Uri.http(domain, "accounts/$accountId"))).body);
  }

  static Future<dynamic> addExternalAccount(String accountHolderName, String iban) async {
    return jsonDecode((await http.post(Uri.http(domain, "external-accounts"),
            headers: <String, String>{
              "Content-Type": "application/json; charset=UTF-8",
            },
            body: jsonEncode({"accountHolderName": accountHolderName, "iban": iban})))
        .body);
  }

  static Future<dynamic> makeTransfer(String accountId, String beneficiaryId, num amount, String label) async {
    return jsonDecode((await http.post(Uri.http(domain, "account/$accountId/transfer"),
            headers: <String, String>{
              "Content-Type": "application/json; charset=UTF-8",
            },
            body: jsonEncode({"beneficiaryId": beneficiaryId, "amount": amount, "label": label})))
        .body);
  }

  static Future<dynamic> confirmOneTimePassword(ValidationOperation operation, String code) async {
    return jsonDecode((await http.post(Uri.http(domain, "validation/sms"),
            headers: <String, String>{
              "Content-Type": "application/json; charset=UTF-8",
            },
            body: jsonEncode({
              "validation": {"operation": operation.toString().split(".").last, "code": code}
            })))
        .body);
  }
}
