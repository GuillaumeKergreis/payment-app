import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/qr_code_scanner.dart';
import 'package:http/http.dart' as http;

import 'package:qr_flutter/qr_flutter.dart';

import 'IngApi.dart';
import 'Transfer.dart';
import 'camera_preview_scanner.dart';

class Pay extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => PayState();
}

class PayState extends State<Pay> {
  Future<dynamic> accounts;
  Future<dynamic> currentAccount;
  Future<dynamic> beneficiaries;
  num amount = 0;
  String label = "";

  @override
  void initState() {
    super.initState();
    accounts = IngApi.getAccounts();
    currentAccount = accounts
        .then((accounts) => accounts["accounts"].firstWhere((account) => account["type"]["code"] == "CA"))
        .then((account) => IngApi.getAccountById(account["uid"]));

    currentAccount.then((value) => print(value));

    beneficiaries = currentAccount.then((account) => IngApi.getBeneficiaries(account["uid"]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Pay'),
        ),
        body: SingleChildScrollView(
            child: Center(
          child: Column(
            children: [
              Column(
                children: [
                  Container(
                    margin: EdgeInsets.all(10),
                    child: Card(
                      elevation: 50,
                      child: FutureBuilder(
                        future: currentAccount,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(
                              'There was an error :(',
                              style: Theme.of(context).textTheme.headline,
                            );
                          } else if (snapshot.hasData) {
                            dynamic account = snapshot.data;
                            print(account);
                            return Column(
                              children: [
                                Container(
                                    margin: EdgeInsets.all(10),
                                    child: Text(
                                      "${account["type"]["label"].toString()}",
                                      style: TextStyle(fontSize: 25),
                                    )),
                                Container(
                                    margin: EdgeInsets.all(5),
                                    child: Text(
                                      "${account["estimatedBalance"] != null ? account["estimatedBalance"]["amount"] : account["availableBalance"]} €",
                                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                                    )),
                              ],
                            );
                          } else {
                            return Container(margin: EdgeInsets.all(50), child: CircularProgressIndicator());
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Card(
                child: Column(
                  children: [
                    Container(
                      child: Text("Select a beneficiary", style: TextStyle(fontSize: 25)),
                      margin: EdgeInsets.all(10),
                    ),
                    FutureBuilder(
                        future: beneficiaries,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(
                              'There was an error :(',
                              style: Theme.of(context).textTheme.headline,
                            );
                          } else if (snapshot.hasData) {
                            dynamic beneficiariesData = snapshot.data;
                            return Container(
                                height: 250,
                                child: ListView.builder(
                                  scrollDirection: Axis.vertical,
                                  shrinkWrap: true,
                                  itemCount: beneficiariesData.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: Colors.grey)),
                                      ),
                                      child: ListTile(
                                          title: Text("${beneficiariesData[index]["owner"]}"),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${beneficiariesData[index]["type"]["label"]} - ${beneficiariesData[index]["label"]}",
                                              ),
                                              if (beneficiariesData[index]["bankName"] != null)
                                                Text(
                                                    "${beneficiariesData[index]["bankName"]} - ${beneficiariesData[index]["bic"]}")
                                            ],
                                          ),
                                          onTap: () async {
                                            dynamic account = await currentAccount;
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) => Transfer(
                                                        currentAccount: account,
                                                        beneficiaryIban: beneficiariesData[index]["label"],
                                                        beneficiaryBic: beneficiariesData[index]["bic"],
                                                        beneficiaryName: beneficiariesData[index]["owner"])));
                                          }),
                                    );
                                  },
                                ));
                          } else {
                            return Container(margin: EdgeInsets.all(50), child: CircularProgressIndicator());
                          }
                        })
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.all(20),
                child: ElevatedButton(
                    style: ButtonStyle(padding: MaterialStateProperty.all(EdgeInsets.all(20))),
                    onPressed: () => Navigator.pushNamed(context, '/$CameraPreviewScanner'),
                    child: Text(
                      "Scan Bank Record",
                      style: TextStyle(fontSize: 30),
                    )),
              ),
              Container(
                margin: EdgeInsets.all(20),
                child: ElevatedButton(
                    style: ButtonStyle(padding: MaterialStateProperty.all(EdgeInsets.all(20))),
                    onPressed: () => Navigator.pushNamed(context, '/$QRViewExample'),
                    child: Text("Scan EPC QR Code", style: TextStyle(fontSize: 30))),
              )
            ],
          ),
        )));
  }
}
