import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:qr_flutter/qr_flutter.dart';

import 'IngApi.dart';

class GetPaid extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => GetPaidState();
}

class GetPaidState extends State<GetPaid> {
  Future<dynamic> accounts;
  Future<dynamic> debitAccount;
  Future<dynamic> bankRecord;
  num amount = 0;
  String label = "";

  @override
  void initState() {
    super.initState();
    accounts = IngApi.getAccounts();
    debitAccount =
        accounts.then((accounts) => accounts["accounts"].firstWhere((account) => account["type"]["code"] == "CA"));
    bankRecord = debitAccount.then((account) => IngApi.getAccountBankRecord(account["uid"]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Get paid'),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder(
                future: bankRecord,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print(snapshot.error);
                    print(snapshot.data);
                    return Text(
                      'There was an error :(',
                      style: Theme.of(context).textTheme.headline5,
                    );
                  } else if (snapshot.hasData) {
                    dynamic bankRecord = snapshot.data;
                    return Column(
                      children: [
                        Container(
                          margin: EdgeInsets.all(10),
                          child: Card(
                            elevation: 50,
                            child: Column(
                              children: [
                                Container(
                                    margin: EdgeInsets.all(10),
                                    child: Text(
                                      "Account details",
                                      style: TextStyle(fontSize: 30, decoration: TextDecoration.underline),
                                    )),
                                Container(
                                    margin: EdgeInsets.all(5),
                                    child:
                                        Text("${bankRecord["ownerAddress"]["name"]}", style: TextStyle(fontSize: 20))),
                                Container(
                                    margin: EdgeInsets.fromLTRB(15, 5, 15, 5),
                                    child: Text("IBAN : ${bankRecord["iban"]}", style: TextStyle(fontSize: 15))),
                                Container(
                                    margin: EdgeInsets.only(bottom: 10),
                                    child: Text("BIC : ${bankRecord["bic"]}", style: TextStyle(fontSize: 15))),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          child: QrImage(
                            data: "BCD\n"
                                "001\n"
                                "1\n"
                                "SCT\n"
                                "${bankRecord["bic"]}\n"
                                "${bankRecord["ownerAddress"]["name"]}\n"
                                "${bankRecord["iban"].toString().replaceAll(" ", "")}\n"
                                "${amount != 0 ? "EUR${amount.toString()}" : ""}\n"
                                "\n"
                                "$label\n"
                                "\n"
                                "",
                            version: QrVersions.auto,
                            size: 250,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Container(margin: EdgeInsets.all(50), child: CircularProgressIndicator());
                  }
                },
              ),
              Card(
                margin: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Container(
                        margin: EdgeInsets.all(10),
                        child: Text(
                          "Transaction information",
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 20, decoration: TextDecoration.underline),
                        )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Amount : "),
                        Container(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: amount.toString()),
                            onChanged: (number) => number.isEmpty ? amount = 0 : amount = num.parse(number),
                          ),
                          width: 50,
                        ),
                        Text("€")
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Label : "),
                        Container(
                          child: TextFormField(
                            controller: TextEditingController(text: label),
                            onChanged: (text) => label = text,
                          ),
                          width: 250,
                        )
                      ],
                    ),
                    Container(
                        margin: EdgeInsets.all(10),
                        child: ElevatedButton(
                            style: ButtonStyle(
                                padding: MaterialStateProperty.all(
                                    EdgeInsets.only(left: 20, right: 20, bottom: 10, top: 10))),
                            onPressed: (() => {setState(() => {})}),
                            child: Text(
                              "Generate transaction QR Code",
                              style: TextStyle(fontSize: 20),
                            ))),
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
