import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:auto_size_text/auto_size_text.dart';

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
                        builder: (context) => _ParkedVehiclesReport(),
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

class _ParkedVehiclesReport extends StatefulWidget {
  _ParkedVehiclesReport({Key key}) : super(key: key);

  @override
  _ParkedVehiclesReportState createState() => _ParkedVehiclesReportState();
}

class _ParkedVehiclesReportState extends State<_ParkedVehiclesReport> {
  Future vehiclesFuture;

  @override
  void initState() {
    super.initState();
    vehiclesFuture = http.get(
        'https://qi2zwrrpuk.execute-api.us-east-1.amazonaws.com/testing/list-vehicles',
        headers: {'x-api-key': 'Alb1A689Ls3yfkef60CpA5HJnat6ry8J2pY4TUQX'});
  }

  @override
  Widget build(BuildContext context) {
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
            debugPrint("${snapshot.error}");
          }

          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
