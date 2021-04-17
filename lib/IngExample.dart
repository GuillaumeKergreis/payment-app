import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:qr_flutter/qr_flutter.dart';

import 'IngApi.dart';

class IngExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => IngExampleState();
}

class IngExampleState extends State<IngExample> {
  Future<dynamic> accounts;
  Future<dynamic> bankRecord;
  num amount = 0;
  String label = "";


  @override
  void initState() {
    super.initState();
    accounts = IngApi.getAccounts();
    bankRecord = accounts.then((accounts) => IngApi.getAccountBankRecord(accounts["accounts"][0]["uid"]));
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('ING accounts'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              FutureBuilder(
                future: accounts,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'There was an error :(',
                      style: Theme.of(context).textTheme.headline,
                    );
                  } else if (snapshot.hasData) {
                    dynamic result = snapshot.data;
                    return Column(
                      children: [
                        Text(
                          "${result['aggregatedBalance'].toString()} €",
                          style: TextStyle(fontSize: 50),
                        ),
                        ListBody(
                            children: result['accounts']
                                .map<Widget>((account) => Container(
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Colors.grey)),
                                    ),
                                    child: ListTile(
                                      title: Text(account["type"]["label"].toString()),
                                      subtitle: Text("${account["ledgerBalance"].toString()} €"),
                                    )))
                                .toList()),

                        // Text(accounts['accounts'][0]['ledgerBalance'].toString()),

                        // ListBody(children: accounts['accounts'].map((account) => Text(account['ledgerBalance'].toString())).toList() as List<Widget>,)
                      ],
                    );
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
              FutureBuilder(
                future: bankRecord,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print(snapshot.error);
                    print(snapshot.data);
                    return Text(
                      'There was an error :(',
                      style: Theme.of(context).textTheme.headline,
                    );
                  } else if (snapshot.hasData) {
                    dynamic bankRecord = snapshot.data;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [Text("IBAN : ${bankRecord["iban"]}")],
                        ),
                        Row(
                          children: [Text("BIC : ${bankRecord["bic"]}")],
                        ),
                        Row(
                          children: [Text("Name : ${bankRecord["ownerAddress"]["name"]}")],
                        ),
                        Row(children: [
                          QrImage(
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
                            size: 300.0,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                        ]),
                      ],
                    );
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
              Form(
                  key: _formKey,
                  child: Column(
                    children: [
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
                              onChanged: (text) => label = text,),
                            width: 250,
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                              onPressed: (() => {
                                    setState(() => {})
                                  }),
                              child: Text("Generate new QR Code"))
                        ],
                      ),
                    ],
                  ))
            ],
          ),
        ));
  }
}


