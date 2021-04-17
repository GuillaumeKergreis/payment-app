// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart=2.9

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'IngApi.dart';
import 'Transfer.dart';
import 'detector_painters.dart';
import 'scanner_utils.dart';

class CameraPreviewScanner extends StatefulWidget {
  const CameraPreviewScanner({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CameraPreviewScannerState();
}

class _CameraPreviewScannerState extends State<CameraPreviewScanner> {
  dynamic _scanResults;
  List<TextLine> _textLines;
  CameraController _camera;
  Detector _currentDetector = Detector.text;
  bool _isDetecting = false;
  CameraLensDirection _direction = CameraLensDirection.back;

  String ibanDetected = "";
  String bicDetected = "";
  String nameDetected = "";

  bool ibanValid = false;
  bool bicValid = false;

  // final BarcodeDetector _barcodeDetector =
  //     FirebaseVision.instance.barcodeDetector();
  // final FaceDetector _faceDetector = FirebaseVision.instance.faceDetector();
  // final ImageLabeler _imageLabeler = FirebaseVision.instance.imageLabeler();
  // final ImageLabeler _cloudImageLabeler =
  //     FirebaseVision.instance.cloudImageLabeler();
  final TextRecognizer _recognizer = FirebaseVision.instance.textRecognizer();

  // final TextRecognizer _cloudRecognizer =
  //     FirebaseVision.instance.cloudTextRecognizer();
  // final DocumentTextRecognizer _cloudDocumentRecognizer =
  //     FirebaseVision.instance.cloudDocumentTextRecognizer();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final CameraDescription description = await ScannerUtils.getCamera(_direction);

    _camera = CameraController(
      description,
      defaultTargetPlatform == TargetPlatform.iOS ? ResolutionPreset.low : ResolutionPreset.max,
    );
    await _camera.initialize();

    await _camera.startImageStream((CameraImage image) {
      if (_isDetecting) return;

      _isDetecting = true;

      ScannerUtils.detect(
        image: image,
        detectInImage: _getDetectionMethod(),
        imageRotation: description.sensorOrientation,
      ).then(
        (dynamic results) async {
          if (_currentDetector == null) return;

          RegExp ibanPattern = RegExp(r"[A-Z]{2,2}[0-9]{2,2}[A-Z0-9 ]{10,30}");

          RegExp bicPattern = RegExp(r"[A-Z]{4}[ ]?[A-Z]{2}[A-Z2-9][A-NP-Z0-9][ ]?([A-Z0-9]{3,3}){0,1}$");

          RegExp namePattern = RegExp(r"[M|MME|Mme]\.? [A-Z]{2,} [A-Za-z]{2,}$");

          VisionText visionText = results;

          List<TextLine> ibanElements = [];
          List<TextLine> bicElements = [];
          List<TextLine> nameElements = [];

          for (TextBlock block in visionText.blocks) {
            for (TextLine line in block.lines) {
              if (ibanPattern.hasMatch(line.text)) {
                if (!ibanValid) {
                  String iban = ibanPattern.stringMatch(line.text);
                  print("IBAN : " + iban);
                  validateIban(iban);
                }
                ibanElements.add(line);
              }
              if (bicPattern.hasMatch(line.text)) {
                if (!bicValid) {
                  String bic = bicPattern.stringMatch(line.text).replaceAll(" ", "");
                  print("BIC : " + bic);
                  validateBic(bic);
                }
                bicElements.add(line);
              }
              if (namePattern.hasMatch(line.text)) {
                nameDetected = namePattern.stringMatch(line.text);
                print("Name : " + nameDetected);
                nameElements.add(line);
              }
            }
          }

          setState(() {
            _scanResults = results;
            _textLines = ibanElements + bicElements + nameElements;
          });
        },
      ).whenComplete(() => _isDetecting = false);
    });
  }

  Future<dynamic> Function(FirebaseVisionImage image) _getDetectionMethod() {
    switch (_currentDetector) {
      case Detector.text:
        return _recognizer.processImage;
      // case Detector.cloudText:
      //   return _cloudRecognizer.processImage;
      // case Detector.cloudDocumentText:
      //   return _cloudDocumentRecognizer.processImage;
      // case Detector.barcode:
      //   return _barcodeDetector.detectInImage;
      // case Detector.label:
      //   return _imageLabeler.processImage;
      // case Detector.cloudLabel:
      //   return _cloudImageLabeler.processImage;
      // case Detector.face:
      //   return _faceDetector.processImage;
    }

    return null;
  }

  Widget _buildResults() {
    const Text noResultsText = Text("No results!");

    if (_scanResults == null || _camera == null || !_camera.value.isInitialized) {
      return noResultsText;
    }

    CustomPainter painter;

    final Size imageSize = Size(
      _camera.value.previewSize.height,
      _camera.value.previewSize.width,
    );

    switch (_currentDetector) {
      // case Detector.barcode:
      //   if (_scanResults is! List<Barcode>) return noResultsText;
      //   painter = BarcodeDetectorPainter(imageSize, _scanResults);
      //   break;
      // case Detector.face:
      //   if (_scanResults is! List<Face>) return noResultsText;
      //   painter = FaceDetectorPainter(imageSize, _scanResults);
      //   break;
      // case Detector.label:
      //   if (_scanResults is! List<ImageLabel>) return noResultsText;
      //   painter = LabelDetectorPainter(imageSize, _scanResults);
      //   break;
      // case Detector.cloudLabel:
      //   if (_scanResults is! List<ImageLabel>) return noResultsText;
      //   painter = LabelDetectorPainter(imageSize, _scanResults);
      //   break;
      default:
        assert(_currentDetector == Detector.text || _currentDetector == Detector.cloudText);
        if (_scanResults is! VisionText) return noResultsText;
        painter = TextDetectorPainter(imageSize, _scanResults, _textLines);
    }

    return CustomPaint(
      painter: painter,
    );
  }

  Widget _buildImage() {
    return Container(
      constraints: const BoxConstraints.expand(),
      child: _camera == null
          ? const Center(
              child: Text(
                'Initializing Camera...',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 30,
                ),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CameraPreview(_camera),
                _buildResults(),
              ],
            ),
    );
  }

  Future<void> _toggleCameraDirection() async {
    if (_direction == CameraLensDirection.back) {
      _direction = CameraLensDirection.front;
    } else {
      _direction = CameraLensDirection.back;
    }

    await _camera.stopImageStream();
    await _camera.dispose();

    setState(() {
      _camera = null;
    });

    await _initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank record detector'),
        // actions: <Widget>[
        //   PopupMenuButton<Detector>(
        //     onSelected: (Detector result) {
        //       _currentDetector = result;
        //     },
        //     itemBuilder: (BuildContext context) => <PopupMenuEntry<Detector>>[
        //       const PopupMenuItem<Detector>(
        //         value: Detector.barcode,
        //         child: Text('Detect Barcode'),
        //       ),
        //       const PopupMenuItem<Detector>(
        //         value: Detector.face,
        //         child: Text('Detect Face'),
        //       ),
        //       const PopupMenuItem<Detector>(
        //         value: Detector.label,
        //         child: Text('Detect Label'),
        //       ),
        //       const PopupMenuItem<Detector>(
        //         value: Detector.cloudLabel,
        //         child: Text('Detect Cloud Label'),
        //       ),
        //       const PopupMenuItem<Detector>(
        //         value: Detector.text,
        //         child: Text('Detect Text'),
        //       ),
        //       const PopupMenuItem<Detector>(
        //         value: Detector.cloudText,
        //         child: Text('Detect Cloud Text'),
        //       ),
        //       const PopupMenuItem<Detector>(
        //         value: Detector.cloudDocumentText,
        //         child: Text('Detect Document Text'),
        //       ),
        //     ],
        //   ),
        // ],
      ),
      body: Stack(
        children: [
          _buildImage(),
          Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsetsDirectional.only(start: 5, end: 5),
                      child: Icon(Icons.account_balance_wallet, color: ibanValid ? Colors.green : Colors.red),
                    ),
                    Text("IBAN : "),
                    Text(ibanDetected),
                    if (ibanValid)
                      IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => ibanValid = false,
                          constraints: BoxConstraints.tightFor())
                    else
                      Container(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                          width: 10,
                          height: 10,
                          margin: EdgeInsetsDirectional.only(start: 10))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Container(
                        margin: EdgeInsetsDirectional.only(start: 5, end: 5),
                        child: Icon(Icons.account_balance, color: bicValid ? Colors.green : Colors.red)),
                    Text("BIC : "),
                    Text(bicDetected),
                    if (bicValid)
                      IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => bicValid = false,
                          constraints: BoxConstraints.tightFor())
                    else
                      Container(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                          width: 10,
                          height: 10,
                          margin: EdgeInsetsDirectional.only(start: 10))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Container(margin: EdgeInsetsDirectional.only(start: 5, end: 5), child: Icon(Icons.account_box)),
                    Text("Name : "),
                    Text(nameDetected)
                  ],
                ),
              ],
            ),
          ),
          if (ibanDetected != "")
            Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                  onPressed: () async {
                    dynamic currentAccount = await IngApi.getAccounts()
                        .then(
                            (accounts) => accounts["accounts"].firstWhere((account) => account["type"]["code"] == "CA"))
                        .then((account) => IngApi.getAccountById(account["uid"]));
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Transfer(
                                currentAccount: currentAccount,
                                beneficiaryIban: ibanDetected,
                                beneficiaryBic: bicDetected,
                                beneficiaryName: nameDetected)));
                  },
                  child: const Text('Make transfer', style: TextStyle(fontSize: 20))),
            )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleCameraDirection,
        child: _direction == CameraLensDirection.back ? const Icon(Icons.camera_front) : const Icon(Icons.camera_rear),
      ),
    );
  }

  @override
  void dispose() {
    _camera.dispose().then((_) {
      // _barcodeDetector.close();
      // _faceDetector.close();
      // _imageLabeler.close();
      // _cloudImageLabeler.close();
      _recognizer.close();
      // _cloudRecognizer.close();
    });

    _currentDetector = null;
    super.dispose();
  }

  Future<bool> validateIban(String iban) async {
    http.Response response = await http.post(Uri.https("wise.com", 'fr/iban/checker'), body: {"userInputIban": iban});
    ibanValid = response.body.contains("Cet IBAN semble correct");
    if (ibanValid) ibanDetected = iban;
    return ibanValid;
  }

  Future<bool> validateBic(String bic) async {
    http.Response response =
        await http.post(Uri.https("wise.com", 'fr/swift-codes/bic-swift-code-checker'), body: {"code": bic});
    bicValid = response.body.contains("Ce SWIFT semble correct");
    if (bicValid) bicDetected = bic;
    return bicValid;
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
                          Text(ibanDetected),
                        ],
                      ),
                      Row(
                        children: [
                          Text("BIC : "),
                          Text(bicDetected),
                        ],
                      ),
                      Row(
                        children: [
                          Text("Beneficiary name : "),
                          Container(
                            width: 150,
                            child: TextField(
                              keyboardType: TextInputType.text,
                              controller: TextEditingController.fromValue(TextEditingValue(text: nameDetected)),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text("Amount : "),
                          Container(
                            width: 100,
                            child: TextField(
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Text("€")
                        ],
                      ),
                      Row(
                        children: [
                          Text("Label : "),
                          Container(
                            width: 200,
                            child: TextField(
                              keyboardType: TextInputType.text,
                            ),
                          )
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
