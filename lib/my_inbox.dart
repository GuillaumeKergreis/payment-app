import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sms/sms.dart';

import 'package:local_auth/local_auth.dart';

import 'package:http/http.dart' as http;

class MyInbox extends StatefulWidget {
  const MyInbox();

  @override
  State createState() {
    return MyInboxState();
  }
}

enum ValidationOperation { DISPLAY_TRANSACTIONS, ADD_TRANSFER_BENEFICIARY, EXTERNAL_TRANSFER }

class MyInboxState extends State {
  SmsQuery query = new SmsQuery();
  SmsReceiver receiver = new SmsReceiver();

  LocalAuthentication localAuth = LocalAuthentication();

  List<SmsMessage> messages = [];

  String lastIngCode;
  ValidationOperation lastIngValidationOperation;

  Map<ValidationOperation, bool> operationAutomaticValidation = {
    ValidationOperation.DISPLAY_TRANSACTIONS: true,
    ValidationOperation.ADD_TRANSFER_BENEFICIARY: true,
    ValidationOperation.EXTERNAL_TRANSFER: true,
  };

  @override
  initState() {
    super.initState();
    // receiver.onSmsReceived.listen((SmsMessage msg) => smsReceived(msg));
    fetchSMS();
  }

  smsReceived(SmsMessage sms) async {
    if (/*sms.sender == "38975" &&*/ sms.body.startsWith("ING")) {
      setState(() {
        lastIngCode = getIngCode(sms);
        lastIngValidationOperation = getIngValidationOperation(sms);
      });

      if (!operationAutomaticValidation[lastIngValidationOperation]) {
        showAlertDialog(context, lastIngValidationOperation, lastIngCode, sms.body);
      } else {
        http.Response response = await fetchValidationApi(lastIngValidationOperation, lastIngCode);
        showSnackBar(response.body);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Automatic ING SMS Validator'),
        ),
        body: Center(
            child: Column(children: [
          Row(children: [Text("Select the automatic actions to perform")]),
          Column(
              children: operationAutomaticValidation.keys
                  .map((operation) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(operation.toString().split(".").last),
                          Switch(
                            value: operationAutomaticValidation[operation],
                            onChanged: (value) {
                              setState(() {
                                operationAutomaticValidation[operation] = value;
                                print(value);
                              });
                            },
                          ),
                        ],
                      ))
                  .toList()),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(children: [Text("Last SMS received :")]),
              Row(children: [Text("Operation : ${lastIngValidationOperation.toString().split(".").last}")]),
              Row(children: [Text("Code : $lastIngCode")]),
            ],
          ),
        ])));
  }

  fetchSMS() async {
    messages = await query.getAllSms;

    SmsMessage lastIngSMS = messages.firstWhere((sms) => /*sms.sender == "38975" &&*/ sms.body.startsWith("ING"));

    lastIngCode = getIngCode(lastIngSMS);
    lastIngValidationOperation = getIngValidationOperation(lastIngSMS);
    setState(() => lastIngCode);
  }

  getIngCode(SmsMessage sms) {
    return sms.body.split(" ").last.replaceAll(".", "");
  }

  ValidationOperation getIngValidationOperation(SmsMessage sms) {
    if (sms.body.contains("Pour visualiser plus de transactions")) {
      return ValidationOperation.DISPLAY_TRANSACTIONS;
    } else if (sms.body.contains("Validation de l'ajout d'un compte externe")) {
      return ValidationOperation.ADD_TRANSFER_BENEFICIARY;
    } else if (sms.body.contains("Validation de votre virement vers un compte externe")) {
      return ValidationOperation.EXTERNAL_TRANSFER;
    } else if (sms.body.contains("Pour autoriser la connexion")) {
      return null; // TODO
    } else {
      return null;
    }
  }

  Future<http.Response> fetchValidationApi(ValidationOperation operation, String code) {
    return http.post(Uri.http('192.168.1.83:8080', 'validation/sms'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'validation': {'operation': operation.toString().split(".").last, 'code': code}
        }));
  }

  showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            // Code to execute.
          },
        ),
      ),
    );
  }

  showAlertDialog(BuildContext context, ValidationOperation operation, String code, String smsBody) {
    // set up the buttons
    Widget cancelButton = FlatButton(
      child: Text("Refuser"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = FlatButton(
      child: Text("Valider"),
      onPressed: () async {
        bool canCheckBiometrics =
            await localAuth.authenticate(localizedReason: 'Please authenticate to perform this operation.');
        if (canCheckBiometrics) {
          http.Response response = await fetchValidationApi(lastIngValidationOperation, lastIngCode);
          Navigator.pop(context);
          showSnackBar(response.body);
        }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Validation manuelle"),
      content: Text("${operation.toString().split(".").last}"
          "\n"
          "$smsBody"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
