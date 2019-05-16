import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicle Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(title: 'Vehicle Management'),
        '/vin-entry': (context) => VinEntryPage(),
      }
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  handleActionRequest(action) async {
    final vin = await Navigator.pushNamed(context, '/vin-entry');

    if (vin == null) {
      return null; // Means user pressed back and implicitly cancelled.
    }

    final responseRaw = await http.get(
        'https://qi2zwrrpuk.execute-api.us-east-1.amazonaws.com/testing/$action?VIN=$vin');

    var response;

    try {
      response = json.decode(responseRaw.body);
    } catch (e) {
      // Ignore, this means the body is empty.
    }

    if (responseRaw.statusCode >= 200 && responseRaw.statusCode < 300) {
      return response;
    } else {
      throw Exception(response["error"]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        // bottom: PreferredSize(
        //   preferredSize: Size(double.infinity, 1.0),
        //   child: LinearProgressIndicator(valueColor:
        //       AlwaysStoppedAnimation<Color>(Colors.orange)),
        // ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.0),
          child: ListView(
            itemExtent: 50.0,
            padding: EdgeInsets.symmetric(vertical: 15.0),
            children: <Widget>[
              RaisedButton.icon(
                onPressed: () async {
                  try {
                    var result = await handleActionRequest('park-in');
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: SingleChildScrollView(
                            child: Text('Vehicle assigned to slot ${result["slot"]}'),
                          ),
                        );
                      },
                    );
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: SingleChildScrollView(
                            child: Text('Error occured: ${e.message}'),
                          ),
                        );
                      }
                    );
                  }
                },
                label: Text('Park In', style: TextStyle(fontSize: 20.0)),
                icon: Icon(Icons.add),
              ),
              SizedBox(width: 30.0),
              RaisedButton.icon(
                onPressed: () async {
                  try {
                    var result = await handleActionRequest('park-out');
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: SingleChildScrollView(
                            child: Text('Vehicle marked as parked out'),
                          ),
                        );
                      }
                    );
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: SingleChildScrollView(
                            child: Text('Error occured: ${e.message}'),
                          ),
                        );
                      }
                    );
                  }
                },
                label: Text('Park Out', style: TextStyle(fontSize: 20.0)),
                icon: Icon(Icons.eject),
              ),
              SizedBox(width: 30.0),
              RaisedButton.icon(
                onPressed: () async {
                  try {
                    var result = await handleActionRequest('maint-in');
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: SingleChildScrollView(
                            child: Text('Vehicle assigned to ${result["slot"]}'),
                          ),
                        );
                      }
                    );
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: SingleChildScrollView(
                            child: Text('Error occured: ${e.message}'),
                          ),
                        );
                      }
                    );
                  }
                },
                label: Text('Maintainence In', style: TextStyle(fontSize: 20.0)),
                icon: Icon(Icons.vertical_align_bottom),
              ),
              SizedBox(width: 30.0),
              RaisedButton.icon(
                onPressed: () async {
                  try {
                    var result = await handleActionRequest('maint-out');
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: SingleChildScrollView(
                            child: Text('Vehicle marked as out for maintainence'),
                          ),
                        );
                      }
                    );
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: SingleChildScrollView(
                            child: Text('Error occured: ${e.message}'),
                          ),
                        );
                      }
                    );
                  }
                },
                label: Text('Maintainence Out', style: TextStyle(fontSize: 20.0)),
                icon: Icon(Icons.vertical_align_top),
              ),
              SizedBox(width: 30.0),
              RaisedButton.icon(
                onPressed: null,
                label: Text('Move', style: TextStyle(fontSize: 20.0)),
                icon: Icon(Icons.open_with),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                TextField(
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
