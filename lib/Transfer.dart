import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:sms/sms.dart';

import 'IngApi.dart';
import 'my_inbox.dart';

class Transfer extends StatefulWidget {
  final dynamic currentAccount;
  final String beneficiaryIban;
  final String beneficiaryBic;
  final String beneficiaryName;
  final num transactionAmount;
  final String transactionLabel;

  Transfer(
      {Key key,
      @required this.currentAccount,
      @required this.beneficiaryIban,
      @required this.beneficiaryBic,
      @required this.beneficiaryName,
      this.transactionAmount,
      this.transactionLabel})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => TransferState(this.currentAccount, this.beneficiaryIban, this.beneficiaryBic,
      this.beneficiaryName, this.transactionAmount, this.transactionLabel);
}

class TransferState extends State<Transfer> {
  dynamic currentAccount;
  String beneficiaryIban;
  String beneficiaryBic;
  String beneficiaryName;
  num transactionAmount;
  String transactionLabel;

  TransferState(this.currentAccount, this.beneficiaryIban, this.beneficiaryBic, this.beneficiaryName,
      this.transactionAmount, this.transactionLabel);

  Future<dynamic> beneficiaries;
  Future<dynamic> beneficiaryFound;

  SmsReceiver receiver = new SmsReceiver();

  @override
  void initState() {
    super.initState();
    beneficiaries = IngApi.getBeneficiaries(currentAccount["uid"]);
    beneficiaryFound = beneficiaries.then((externalAccounts) => (externalAccounts as List<dynamic>).firstWhere(
        (externalAccount) =>
            (beneficiaryIban == externalAccount["label"] &&
                beneficiaryBic == externalAccount["bic"] &&
                beneficiaryName == externalAccount["owner"]) ||
            (beneficiaryIban.replaceAll(" ", "").endsWith(externalAccount["label"].toString().split(" ").last) &&
                beneficiaryBic.replaceAll(" ", "").startsWith(externalAccount["bic"].toString().replaceAll("XXX", ""))),
        orElse: () => false));
    beneficiaryFound.then((beneficiary) {
      if (beneficiary != false) {
        beneficiaryIban = beneficiary["label"];
        beneficiaryBic = beneficiary["bic"];
        beneficiaryName = beneficiary["owner"];
        setState(() {});
      }
    });
    receiver.onSmsReceived.listen((SmsMessage msg) => smsReceived(msg));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Make transfer'),
        ),
        body: SingleChildScrollView(
            child: Center(
          child: Column(
            children: [
              Card(
                  margin: EdgeInsets.all(10),
                  elevation: 50,
                  child: Column(
                    children: [
                      Container(
                          margin: EdgeInsets.only(left: 40, right: 40, top: 10, bottom: 10),
                          child: Text(
                            "ING - ${currentAccount["type"]["label"].toString()}",
                            style: TextStyle(fontSize: 25),
                          )),
                      Container(
                          margin: EdgeInsets.all(5),
                          child: Text(
                            "${currentAccount["estimatedBalance"] != null ? currentAccount["estimatedBalance"]["amount"] : currentAccount["availableBalance"]} €",
                            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                          )),
                    ],
                  )),
              Text("ǀ", style: TextStyle(fontSize: 80, height: 1)),
              Card(
                  elevation: 50,
                  margin: EdgeInsets.only(left: 50, right: 50),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 5, bottom: 10),
                            width: 150,
                            child: TextField(
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontSize: 25),
                                controller: TextEditingController(
                                    text: transactionAmount != null ? transactionAmount.toString() : ""),
                                decoration: InputDecoration(suffixIcon: Icon(Icons.euro), hintText: "Amount"),
                                onSubmitted: (amount) =>
                                    {transactionAmount = num.tryParse(amount) ?? null, setState(() => {})}),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: 20),
                            width: 200,
                            child: TextField(
                                style: TextStyle(fontSize: 20),
                                textAlign: TextAlign.center,
                                controller: TextEditingController(text: transactionLabel),
                                decoration: InputDecoration(suffixIcon: Icon(Icons.edit), hintText: "Label"),
                                onChanged: (label) => transactionLabel = label),
                          ),
                        ],
                      )
                    ],
                  )),
              Icon(Icons.arrow_downward, size: 80),
              Container(
                margin: EdgeInsets.only(left: 10, right: 10),
                child: Card(
                  elevation: 50,
                  child: Column(
                    children: [
                      FutureBuilder(
                          future: beneficiaryFound,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text(
                                'There was an error :(',
                                style: Theme.of(context).textTheme.headline,
                              );
                            } else if (snapshot.hasData) {
                              if (snapshot.data != false) {
                                return Text(beneficiaryName, style: TextStyle(fontSize: 20));
                              } else {
                                return Container(
                                    width: 250,
                                    child: TextField(
                                      textAlign: TextAlign.center,
                                      controller: TextEditingController(text: beneficiaryName),
                                      style: TextStyle(fontSize: 20),
                                      onChanged: (value) => beneficiaryName = value,
                                    ));
                              }
                            } else
                              return CircularProgressIndicator();
                          }),
                      Container(
                          margin: EdgeInsets.fromLTRB(15, 5, 15, 5),
                          child: Text(beneficiaryIban, style: TextStyle(fontSize: 15))),
                      Container(
                          margin: EdgeInsets.all(10), child: Text(beneficiaryBic, style: TextStyle(fontSize: 15))),
                      Container(
                          margin: EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Already a beneficiary : "),
                              FutureBuilder(
                                future: beneficiaryFound,
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Text(
                                      'There was an error :(',
                                      style: Theme.of(context).textTheme.headline,
                                    );
                                  } else if (snapshot.hasData) {
                                    return snapshot.data != false
                                        ? Icon(
                                            Icons.cloud_done,
                                            color: Colors.green,
                                          )
                                        : Icon(
                                            Icons.cloud_off,
                                            color: Colors.red,
                                          );
                                  } else
                                    return Container(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                        width: 10,
                                        height: 10,
                                        margin: EdgeInsetsDirectional.only(start: 10));
                                },
                              )
                            ],
                          )),
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(20),
                child: FutureBuilder(
                  future: beneficiaryFound,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'There was an error :(',
                        style: Theme.of(context).textTheme.headline,
                      );
                    } else if (snapshot.hasData) {
                      if (snapshot.data != false) {
                        return ElevatedButton(
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(EdgeInsets.all(20)),
                            ),
                            onPressed: transactionAmount != null && transactionAmount != 0
                                ? () async {
                                    dynamic beneficiary = snapshot.data;
                                    print(beneficiary["uid"]);
                                    print(transactionAmount);
                                    print(transactionLabel);
                                    dynamic response = await IngApi.makeTransfer(
                                        currentAccount["uid"], beneficiary["uid"], transactionAmount, transactionLabel);
                                    if (response["error"] != null) showSnackBar(response["error"]["message"]);
                                    print(response);
                                  }
                                : null,
                            child: Text(
                              "Make transfer",
                              style: TextStyle(fontSize: 20),
                              textAlign: TextAlign.center,
                            ));
                      } else if (snapshot.data == false && (transactionAmount != 0 && transactionAmount != null)) {
                        return ElevatedButton(
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(EdgeInsets.all(20)),
                            ),
                            onPressed: transactionAmount != null && transactionAmount != 0
                                ? () async {
                                    dynamic addBeneficiaryResponse =
                                        await IngApi.addExternalAccount(beneficiaryName, beneficiaryIban);
                                    print(addBeneficiaryResponse);
                                    if (addBeneficiaryResponse["error"] != null)
                                      showSnackBar(addBeneficiaryResponse["error"]["message"]);
                                    else {
                                      dynamic validatedBeneficiary = await waitBeneficiaryValidation()
                                          .timeout(Duration(seconds: 30), onTimeout: () => showSnackBar("Temps d'attente de réception du SMS écoulé."));
                                      print(validatedBeneficiary);
                                      if (validatedBeneficiary != null) {
                                        dynamic transferRequestResponse = await IngApi.makeTransfer(currentAccount["uid"], validatedBeneficiary["uid"],
                                            transactionAmount, transactionLabel);
                                        print(transferRequestResponse);
                                        if (transferRequestResponse["error"] != null) showSnackBar(transferRequestResponse["error"]["message"]);
                                      }
                                    }
                                  }
                                : null,
                            child: Text(
                              "Add beneficiary and make transfer",
                              style: TextStyle(fontSize: 20),
                              textAlign: TextAlign.center,
                            ));
                      } else {
                        return ElevatedButton(
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(EdgeInsets.all(20)),
                            ),
                            onPressed: () async {
                              dynamic addBeneficiaryResponse =
                                  await IngApi.addExternalAccount(beneficiaryName, beneficiaryIban);
                              if (addBeneficiaryResponse["error"] != null)
                                showSnackBar(addBeneficiaryResponse["error"]["message"]);
                            },
                            child: Text(
                              "Add beneficiary",
                              style: TextStyle(fontSize: 20),
                              textAlign: TextAlign.center,
                            ));
                      }
                    } else
                      return CircularProgressIndicator();
                  },
                ),
              )
            ],
          ),
        )));
  }

  Future<dynamic> waitBeneficiaryValidation() async {
    dynamic validatedBeneficiary;
    await Future.doWhile(() async {
      num getBeneficiariesRequestCounter = 0;
      await Future.delayed(Duration(seconds: 2), () => {});
      List<dynamic> newBeneficiaries = await IngApi.getBeneficiaries(currentAccount["uid"]);
      print("Get beneficiaries");
      dynamic newBeneficiaryFound = newBeneficiaries.firstWhere(
              (externalAccount) =>
          beneficiaryIban.replaceAll(" ", "").endsWith(externalAccount["label"].toString().split(" ").last) &&
              beneficiaryBic.replaceAll(" ", "").startsWith(externalAccount["bic"].toString().replaceAll("XXX", "")),
          orElse: () => null);
      if (newBeneficiaryFound != null) {
        print("Beneficiary added");
        validatedBeneficiary = newBeneficiaryFound;
        return false;
      } else if (getBeneficiariesRequestCounter > 30) {
        return false;
      } else {
        print("Beneficiary not found");
        getBeneficiariesRequestCounter ++;
        return true;
      }
    });
    return validatedBeneficiary;
  }

  smsReceived(SmsMessage sms) async {
    if (sms.sender == "38975" && sms.body.startsWith("ING")) {
      String code = getIngCode(sms);
      ValidationOperation validationOperation = getIngValidationOperation(sms);
      dynamic confirmOtpResponse = await IngApi.confirmOneTimePassword(validationOperation, code);
      setState(() {});
      showSnackBar(confirmOtpResponse.toString());
    }
  }

  getIngCode(SmsMessage sms) {
    return sms.body.split(" ").last.trim().replaceAll(".", "").replaceAll("\n", "");
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

  showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 60),
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
}
