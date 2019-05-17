import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
          '/reports': (context) => ReportsPage(),
        });
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showLoadingIndicator = false;

  handleActionRequest(action) async {
    final vin = await Navigator.pushNamed(context, '/vin-entry');

    if (vin == null) {
      return -1; // Means user pressed back and implicitly cancelled.
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

  Widget makeActionButton(BuildContext context, String actionName,
      String actionFriendlyName, Function successMessage, IconData icon) {
    return RaisedButton(
      onPressed: () async {
        try {
          setState(() {
            _showLoadingIndicator = true;
          });

          var result = await handleActionRequest(actionName);

          if (result == -1) {
            return;
          }

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: SingleChildScrollView(
                  child: Text(successMessage(result)),
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
            },
          );
        } finally {
          setState(() {
            _showLoadingIndicator = false;
          });
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: IconTheme.of(context).size * 2),
          Text(actionFriendlyName, style: TextStyle(fontSize: 20.0)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: Size(double.infinity, 2.0),
          child: Visibility(
            child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange)),
            visible: _showLoadingIndicator,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(5.0),
        child: OrientationBuilder(
          builder: (context, orientation) {
            return GridView.count(
              crossAxisCount: orientation == Orientation.landscape ? 4 : 2,
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
              children: <Widget>[
                makeActionButton(
                    context,
                    'park-in',
                    'Park In',
                    (result) => 'Vehicle assigned to slot ${result["slot"]}',
                    Icons.add),
                makeActionButton(context, 'park-out', 'Park Out',
                    (result) => 'Vehicle marked as parked out', Icons.eject),
                makeActionButton(
                    context,
                    'maint-in',
                    'Maintainence In',
                    (result) => 'Vehicle assigned to slot ${result["slot"]}',
                    Icons.vertical_align_bottom),
                makeActionButton(
                    context,
                    'maint-out',
                    'Maintainence Out',
                    (result) => 'Vehicle marked as out for maintainence',
                    Icons.vertical_align_top),
                RaisedButton(
                  onPressed: null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.open_with,
                          size: IconTheme.of(context).size * 2),
                      Text('Move', style: TextStyle(fontSize: 20.0)),
                    ],
                  ),
                ),
                RaisedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/reports');
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.assessment,
                          size: IconTheme.of(context).size * 2),
                      Text('Reports', style: TextStyle(fontSize: 20.0)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ReportsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
      ),
      body: Padding(
        padding: EdgeInsets.all(5.0),
        child: OrientationBuilder(
          builder: (context, orientation) {
            return GridView.count(
              crossAxisCount: orientation == Orientation.landscape ? 4 : 2,
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
              children: <Widget>[
                RaisedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (BuildContext context) {
                          var vehiclesFuture = http.get(
                              'https://qi2zwrrpuk.execute-api.us-east-1.amazonaws.com/testing/list-vehicles');

                          return Scaffold(
                            body: FutureBuilder(
                              future: vehiclesFuture,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  var vehicles =
                                      json.decode(snapshot.data.body)["Items"];

                                  var vehiclesInLot = vehicles
                                      .where((vehicle) =>
                                          vehicle["in_lot"] as bool)
                                      .toList();

                                  if (vehiclesInLot.length > 0) {
                                    return Center(
                                        child: DataTable(
                                          rows: vehiclesInLot.map<DataRow>((vehicle) {
                                            return DataRow(
                                              cells: <DataCell>[
                                                DataCell(Text(vehicle["VIN"])),
                                                DataCell(Text(vehicle["current_slot"]))
                                              ],
                                            );
                                          }).toList(),
                                          columns: <DataColumn>[
                                            DataColumn(label: Text('VIN')),
                                            DataColumn(label: Text('Slot')),
                                          ],
                                      ),
                                    );
                                  } else {
                                    return Center(
                                      child: Text('There are no vehicles in the lot.'),
                                    );
                                  }
                                } else if (snapshot.hasError) {
                                  debugPrint("Oh no");
                                }

                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: AutoSizeText('Currently parked vehicles',
                      style: TextStyle(fontSize: 30.0),
                      textAlign: TextAlign.center,
                      maxLines: 3),
                ),
                RaisedButton(
                  onPressed: null,
                  child: AutoSizeText('Vehicles currently out for maintainence',
                      style: TextStyle(fontSize: 30.0),
                      textAlign: TextAlign.center,
                      maxLines: 3),
                ),
                RaisedButton(
                  onPressed: null,
                  child: AutoSizeText('Parked out vehicles',
                      style: TextStyle(fontSize: 30.0),
                      textAlign: TextAlign.center,
                      maxLines: 3),
                ),
                RaisedButton(
                  onPressed: null,
                  child: AutoSizeText('Most recent entries',
                      style: TextStyle(fontSize: 30.0),
                      textAlign: TextAlign.center,
                      maxLines: 3),
                ),
                RaisedButton(
                  onPressed: null,
                  child: AutoSizeText('Status of all slots',
                      style: TextStyle(fontSize: 30.0),
                      textAlign: TextAlign.center,
                      maxLines: 3),
                ),
              ],
            );
          },
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
