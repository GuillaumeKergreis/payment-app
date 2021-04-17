import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'IngApi.dart';
import 'Transfer.dart';

// void main() => runApp(MaterialApp(home: QRViewExample()));

class QRViewExample extends StatefulWidget {
  const QRViewExample();

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode result;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  String name = "";
  String iban = "";
  String bic = "";
  num amount = 0;
  String label = "";

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.pauseCamera();
    }
    controller.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (result != null)
                    Column(
                      children: [
                        Text('Name : ${result.code.split("\n")[5]}'),
                        Text('IBAN : ${result.code.split("\n")[6]}'),
                        Text('BIC : ${result.code.split("\n")[4]}'),
                        if (amount != 0) Text('Amount : ${result.code.split("\n")[7].replaceAll("EUR", "")} €'),
                        if (label.isNotEmpty)
                          Text(
                              'Label : ${result.code.split("\n")[9].isNotEmpty ? result.code.split("\n")[9] : result.code.split("\n")[10]}')
                      ],
                    )
                  else
                    Container(child: Text('Scan an EPC QR code'), width: 200, alignment: Alignment.center),
                  if (iban != "")
                    Align(
                        alignment: Alignment.bottomCenter,
                        child: ElevatedButton(
                            onPressed: () async {
                              dynamic currentAccount = await IngApi.getAccounts()
                                  .then((accounts) =>
                                      accounts["accounts"].firstWhere((account) => account["type"]["code"] == "CA"))
                                  .then((account) => IngApi.getAccountById(account["uid"]));
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Transfer(
                                            currentAccount: currentAccount,
                                            beneficiaryIban: iban,
                                            beneficiaryBic: bic,
                                            beneficiaryName: name,
                                            transactionAmount: amount,
                                            transactionLabel: label,
                                          )));
                            },
                            child: const Text('Make transfer', style: TextStyle(fontSize: 20)))),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea =
        (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400) ? 150.0 : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red, borderRadius: 10, borderLength: 30, borderWidth: 10, cutOutSize: scanArea),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      String content = scanData.code;
      setState(() {
        result = scanData;
        name = content.split("\n")[5];
        iban = content.split("\n")[6];
        bic = content.split("\n")[4];
        amount = content.split("\n")[7].isNotEmpty ? num.parse(content.split("\n")[7].replaceAll("EUR", "")) : 0;
        label = content.split("\n")[9].isNotEmpty ? result.code.split("\n")[9] : result.code.split("\n")[10];
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _showBottomSheet() {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          width: double.infinity,
          height: 368,
          child: Column(
            children: <Widget>[
              Container(
                height: 56,
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Transfer details",
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: [
                          Text("IBAN : "),
                          Text(iban),
                        ],
                      ),
                      Row(
                        children: [
                          Text("BIC : "),
                          Text(bic),
                        ],
                      ),
                      Row(
                        children: [Text("Beneficiary name : "), Text(name)],
                      ),
                      if (amount != 0)
                        Row(
                          children: [Text("Amount : "), Text(amount.toString()), Text("€")],
                        ),
                      if (label.isNotEmpty)
                        Row(
                          children: [
                            Text("Label : "),
                            Text(label),
                          ],
                        ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 4),
                          alignment: Alignment.bottomCenter,
                          child: ButtonTheme(
                            minWidth: 312,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                elevation: 8,
                                shape: const BeveledRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(7),
                                  ),
                                ),
                              ),
                              label: const Text('Send a transfer'),
                              icon: const Icon(Icons.send),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
