import 'package:flutter/material.dart';
import 'package:flutter_app/qr_code_scanner.dart';

import 'GetPaid.dart';
import 'IngExample.dart';
import 'Pay.dart';
import 'Transfer.dart';
import 'camera_preview_scanner.dart';
import 'my_inbox.dart';
import 'picture_scanner.dart';

void main() {
  // debugPrint = (String message, {int wrapWidth}) {};
  runApp(
    MaterialApp(
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => _ExampleList(),
        '/$PictureScanner': (BuildContext context) => const PictureScanner(),
        '/$CameraPreviewScanner': (BuildContext context) => const CameraPreviewScanner(),
        '/$MyInbox': (BuildContext context) => const MyInbox(),
        '/$QRViewExample': (BuildContext context) => const QRViewExample(),
        '/$IngExample': (BuildContext context) => IngExample(),
        '/$Pay': (BuildContext context) => Pay(),
        '/$GetPaid': (BuildContext context) => GetPaid(),
        '/$Transfer': (BuildContext context) => Transfer(),
      },
    ),
  );
}

class _ExampleList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ExampleListState();
}

class _ExampleListState extends State<_ExampleList> {
  static final List<String> _exampleWidgetNames = <String>[
    '$PictureScanner',
    '$CameraPreviewScanner',
    '$MyInbox',
    '$QRViewExample',
    '$IngExample'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Example List'),
        ),
        body: Column(
          children: [
            ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: _exampleWidgetNames.length,
              itemBuilder: (BuildContext context, int index) {
                final String widgetName = _exampleWidgetNames[index];
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey)),
                  ),
                  child: ListTile(
                    title: Text(widgetName),
                    onTap: () => Navigator.pushNamed(context, '/$widgetName'),
                  ),
                );
              },
            ),
            Container(
              margin: EdgeInsets.all(20),
              child: ElevatedButton(
                  style: ButtonStyle(padding: MaterialStateProperty.all(EdgeInsets.all(20))),
                  onPressed: () => Navigator.pushNamed(context, '/$Pay'),
                  child: Text(
                    "Pay",
                    style: TextStyle(fontSize: 30),
                  )),
            ),
            Container(
              margin: EdgeInsets.all(20),
              child: ElevatedButton(
                  style: ButtonStyle(padding: MaterialStateProperty.all(EdgeInsets.all(20))),
                  onPressed: () => Navigator.pushNamed(context, '/$GetPaid'),
                  child: Text("Get Paid", style: TextStyle(fontSize: 30))),
            )
          ],
        ));
  }
}
