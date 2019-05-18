import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
        'https://qi2zwrrpuk.execute-api.us-east-1.amazonaws.com/testing/$action?VIN=$vin',
        headers: {'x-api-key': 'Alb1A689Ls3yfkef60CpA5HJnat6ry8J2pY4TUQX'});

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
                actions: <Widget>[
                  FlatButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.pop(context);
                    }
                  ),
                ],
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
                actions: <Widget>[
                  FlatButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.pop(context);
                    }
                  ),
                ],
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

