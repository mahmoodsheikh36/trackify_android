import 'package:flutter/material.dart';

import 'package:trackify_android/ui/widgets/music_lists.dart';
import 'package:trackify_android/db/models.dart';
import 'package:trackify_android/static.dart';

class HomeWidget extends StatelessWidget {
  Map<Track, Duration> topTracksToday;
  Map<Track, Duration> topTracksThisWeek;
  Map<Track, Duration> topTracksThisMonth;

  HomeWidget() {
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
                      //Navigator.push(
                      //  context,
                      //  MaterialPageRoute(
                      //    builder: (context) => MonthlyReportsWidget(apiClient),
                      //  ),
                      //);
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
