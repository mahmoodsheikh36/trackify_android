import 'package:intl/intl.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:trackify_android/config.dart';
import 'package:trackify_android/db/models.dart';
import 'package:trackify_android/api/api.dart';
import 'package:trackify_android/api/auth.dart';
import 'package:trackify_android/widgets/music_widgets.dart';
import 'package:trackify_android/widgets/auth_widgets.dart';

class PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/placeholder.png');
  }
}

class RootWidget extends StatefulWidget {
  final APIClient apiClient;

  RootWidget(this.apiClient);

  @override
  State<StatefulWidget> createState() => RootWidgetState();
}

class RootWidgetState extends State<RootWidget> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder(
        future: () async {
          await widget.apiClient.init();
          //List<Map<String, dynamic>> plays = await widget.apiClient.dbProvider.getPlays();
        }(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (widget.apiClient.isAuthDone()) {
              return AfterAuthWidget(widget.apiClient);
            } else {
              return AuthWidget(widget.apiClient, this);
            }
          } else {
            return Scaffold(
              backgroundColor: mainBlack,
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      )
    );
  }
}

class MainContainerWidget extends StatelessWidget {
  Widget child;
  Widget bottomNavigationBar;

  MainContainerWidget({this.child, this.bottomNavigationBar});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          backgroundColor: mainBlack,
          body: this.child,
          bottomNavigationBar: this.bottomNavigationBar != null ? this.bottomNavigationBar : null,
        ),
      ),
    );
  }
}

class HomeWidget extends StatelessWidget {
  final APIClient apiClient;
  Map<Track, Duration> topTracksToday;
  Map<Track, Duration> topTracksThisWeek;
  Map<Track, Duration> topTracksThisMonth;

  HomeWidget(this.apiClient) {
    topTracksToday = apiClient.data.topTracksToday();
    topTracksThisWeek = apiClient.data.topTracksThisWeek();
    topTracksThisMonth = apiClient.data.topTracksThisMonth();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            child: Text('Good day', style: TextStyle(color: mainRed, fontSize: 21)),
            padding: EdgeInsets.fromLTRB(15, 15, 0, 5),
          ),
          Container(
            child: Row(
              children: [
                Expanded(
                  child: FlatButton(
                    onPressed: () {
                    },
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      'Yearly reports',
                      style: TextStyle(fontSize: 17, color: mainRed),
                    ),
                    color: tertiaryBlack,
                    splashColor: secondaryBlack,
                  )
                ),
                SizedBox(width: 5),
                Expanded(
                  child: FlatButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MonthlyReportsWidget(this.apiClient),
                        ),
                      );
                    },
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      'Monthly reports',
                      style: TextStyle(fontSize: 17, color: mainRed),
                    ),
                    color: tertiaryBlack,
                    splashColor: secondaryBlack,
                  )
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(10, 0, 10, 5)
          ),
          Container(
            child: Row(
              children: [
                Expanded(
                  child: FlatButton(
                    onPressed: () {
                    },
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      'Weekly reports',
                      style: TextStyle(fontSize: 17, color: mainRed),
                    ),
                    color: tertiaryBlack,
                    splashColor: secondaryBlack,
                  )
                ),
                SizedBox(width: 5),
                Expanded(
                  child: FlatButton(
                    onPressed: () {
                    },
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      'Daily reports',
                      style: TextStyle(fontSize: 17, color: mainRed),
                    ),
                    color: tertiaryBlack,
                    splashColor: secondaryBlack,
                  )
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(10, 0, 10, 5)
          ),
          if (this.topTracksToday != null) HorizontalTrackListWidget(
            title: 'Top tracks today',
            tracks: this.topTracksToday,
          ),
          if (this.topTracksThisWeek != null) HorizontalTrackListWidget(
            title: 'Top tracks this week',
            tracks: this.topTracksThisWeek,
          ),
          if (this.topTracksThisMonth != null) HorizontalTrackListWidget(
            title: 'Top tracks this month',
            tracks: this.topTracksThisMonth,
          ),
        ],
    ));
  }
}

class FormButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  FormButton(this.text, this.onPressed);

  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: this.onPressed,
      padding: EdgeInsets.all(10.0),
      child: Text(
        this.text,
        style: TextStyle(fontSize: 20)
      ),
      color: secondaryBlack,
      splashColor: mainRed,
    );
  }
}

class GeneralPage extends StatelessWidget {
  Widget content;
  Widget title;
  Widget controls;

  GeneralPage({this.title, this.controls, this.content});

  @override
  Widget build(BuildContext context) {
    return MainContainerWidget(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: mainRed,
              borderRadius: BorderRadius.only(
                bottomLeft: const Radius.circular(30.0),
                bottomRight: const Radius.circular(30.0),
              )
            ),
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: mainBlack),
                    tooltip: "close",
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  width: 30,
                ),
                this.title,
                this.controls != null ? this.controls : Container(width: 30),
              ],
            ),
          ),
          Container(height: 5),
          Expanded(child: this.content),
        ],
      ),
    );
  }
}

class MonthlyReportsWidget extends StatelessWidget {
  APIClient apiClient;

  MonthlyReportsWidget(this.apiClient);

  @override
  Widget build(BuildContext context) {
    DateTime firstPlayTime = apiClient.data.firstPlayDateTime();
    firstPlayTime = DateTime(firstPlayTime.year, firstPlayTime.month);
    DateTime lastPlayTime = apiClient.data.lastPlayDateTime();
    lastPlayTime = DateTime(lastPlayTime.year, lastPlayTime.month);
    List<DateTime> months = [];
    for (DateTime time = lastPlayTime; time.isAfter(firstPlayTime) || time.isAtSameMomentAs(firstPlayTime);
         time = DateTime(time.year, time.month - 1)) {
      months.add(time);
    }
    return GeneralPage(
      title: Text('Monthly reports', style: TextStyle(color: mainRed, fontSize: 21)),
      content: ListView.builder(
        itemCount: months.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            padding: EdgeInsets.all(10),
            child: FlatButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReportWidget()),
                );
              },
              padding: EdgeInsets.all(20),
              child: Text(
                DateFormat("MMMM (M) yyyy").format(months[index]),
                style: TextStyle(fontSize: 17, color: mainRed),
              ),
              color: tertiaryBlack,
              splashColor: secondaryBlack,
            )
          );
        }
      ),
    );
  }
}

class ReportWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GeneralPage(
      title: Text('January report', style: TextStyle(color: mainRed, fontSize: 21)),
      content: Column(
        children: [
          Container(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: mainRed, size: 60),
              Container(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: mainRed),
                      Container(width: 2),
                      Text('390 hrs 80 mins 30 secs', style: TextStyle(color: secondaryBlack)),
                    ]
                  ),
                  Text('1312 tracks played', style: TextStyle(color: secondaryBlack)),
                  Text('289 artists listened to', style: TextStyle(color: secondaryBlack)),
                ]
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.all(20),
            color: tertiaryBlack,
            height: 200,
            child: charts.LineChart(
              _generateChartData(),
              defaultRenderer: new charts.LineRendererConfig(includePoints: true),
            ),
          ),
        ],
      ),
    );
  }

  List<charts.Series<List<int>, int>> _generateChartData() {
    final data = [
      [1, 1],
      [2, 3],
      [3, 5],
      [4, 7],
      [5, 9],
    ];

    return [
      charts.Series<List<int>, int>(
        id: 'whatever',
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(mainRed),
        domainFn: (final piece, _) => piece[0],
        measureFn: (final piece, _) => piece[1],
        data: data,
      )
    ];
  }
}
