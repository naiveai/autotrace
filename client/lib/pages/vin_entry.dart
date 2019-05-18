import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';

class VinEntryPage extends StatefulWidget {
  VinEntryPage({Key key}) : super(key: key);

  @override
  _VinEntryPageState createState() => _VinEntryPageState();
}

class _VinEntryPageState extends State<VinEntryPage> {
  Future<String> _scanCode() async {
    try {
      String result = await BarcodeScanner.scan();

      return result;
    } on PlatformException catch (pe) {
      if (pe.code == BarcodeScanner.CameraAccessDenied) {
        throw Exception("Camera permission was denied. Enter VIN manually.");
      } else {
        throw Exception(
            "An unknown error occured: $pe. Try again or enter VIN manually.");
      }
    } on FormatException {
      throw Exception("No scan detected. Try again.");
    }
  }

  final vinFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: (BuildContext context) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(9.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlatButton(
                  onPressed: () async {
                    try {
                      String vin = await _scanCode();
                      Navigator.pop(context, vin);
                    } catch (e) {
                      Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text(e.message),
                          duration: Duration(seconds: 5)));
                    }
                  },
                  child: Text('SCAN VIN BARCODE'),
                ),
                Text.rich(TextSpan(
                    text: 'or', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(height: 10.0),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: vinFieldController,
                        autocorrect: false,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Enter VIN Number',
                        ),
                        textInputAction: TextInputAction.go,
                        onEditingComplete: () {
                          Navigator.pop(context, vinFieldController.text);
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.subdirectory_arrow_left),
                      tooltip: 'Enter',
                      onPressed: () {
                        Navigator.pop(context, vinFieldController.text);
                      }
                    ),
                  ]
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    vinFieldController.dispose();
    super.dispose();
  }
}
