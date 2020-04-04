import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';

void main() => runApp(new BarcodeSorter());

class BarcodeSorter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new ScannerState();
  }
}

class ScannerState extends State<BarcodeSorter> {
  final url = "https://zotbins.pythonanywhere.com/barcode/get";
  String barcode = "";

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text("Barcode Waste Sorter"),
        ),
        body: Builder(builder: (context) => new Center(
          child: new Ink(
            decoration: const ShapeDecoration(
              color: Colors.lightBlue,
              shape: CircleBorder(),
            ),
            child: IconButton(
                color: Colors.white,
                padding: new EdgeInsets.all(16.0),
                iconSize: 190, //constraint.biggest.height,
                icon: new Icon(
                  Icons.camera_alt,
                  size: 170, //constraint.biggest.height/2,
                ),
                onPressed: () {
                  scan(context);
                }),
          ),
        ),
        ),
      ),
    );
  }

  Future scan(context) async {
    try {
      String barcode = await BarcodeScanner.scan();
      setState(() => this.barcode = barcode);
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          this.barcode = 'The user did not grant the camera permission!';
        });
      } else {
        setState(() => this.barcode = 'Unknown error: $e');
      }
    } on FormatException {
      setState(() => this.barcode =
          'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      setState(() => this.barcode = 'Unknown error: $e');
    }
    showAlertDialog(context, this.barcode, this.url);
  }

  Future<Map> getResponse(String url, String barcode) async {
    //API call using specified base url
    String requestURL = url+"?barcode="+barcode;
    final response = await http.get(requestURL);

    return json.decode(response.body) == null ?
    {"instructions":"This database will be updated","name":"Barcode Not Found"}:
    json.decode(response.body);
  }

  Future showAlertDialog(BuildContext context, String barcode, String url) async {
    //make the GET API request and parse the data
    Map realTimeBarcodeResponse = await getResponse(url, barcode);
    String itemName = realTimeBarcodeResponse["name"];
    String instructions = realTimeBarcodeResponse["instructions"];

    // set up the buttons
    Widget cancelButton = FlatButton(
      child: Text("Correct"),
      onPressed: () {},
    );
    Widget continueButton = FlatButton(
      child: Text("Wrong"),
      onPressed: () {},
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(itemName),
      content:
        Text(instructions),
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

