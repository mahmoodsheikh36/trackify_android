import 'package:flutter/material.dart';

import 'package:trackify_android/static.dart';
import 'package:trackify_android/api/api.dart';
import 'package:trackify_android/db/models.dart';
import 'package:trackify_android/ui/widgets/music.dart';

enum LeaderboardType {
  TODAY, THIS_WEEK, THIS_MONTH
}

class LeaderboardWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LeaderboardWidgetState();
}

class LeaderboardWidgetState extends State<LeaderboardWidget> {
  LeaderboardType type = LeaderboardType.TODAY;
  List<int> _indicesOfWidgetsToExpand = [];
  bool _reload = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(0, 20, 0, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25.0), topLeft: Radius.circular(25.0)),
                child: FlatButton(
                  onPressed: () {
                    setState(() {
                        this.type = LeaderboardType.TODAY;
                        this._reload = true;
                        this._indicesOfWidgetsToExpand = [];
                    });
                  },
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    'Today',
                    style: TextStyle(fontSize: 17)
                  ),
                  color: this.type == LeaderboardType.TODAY ? mainRed : secondaryBlack,
                  splashColor: mainRed,
                ),
              ),
              FlatButton(
                onPressed: () {
                  setState(() {
                      this.type = LeaderboardType.THIS_WEEK;
                      this._reload = true;
                      this._indicesOfWidgetsToExpand = [];
                  });
                },
                padding: EdgeInsets.all(10.0),
                child: Text(
                  'This week',
                  style: TextStyle(fontSize: 17)
                ),
                color: this.type == LeaderboardType.THIS_WEEK ? mainRed : secondaryBlack,
                splashColor: mainRed,
              ),
              ClipRRect(
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(25.0), topRight: Radius.circular(25.0)),
                child: FlatButton(
                  onPressed: () {
                    setState(() {
                        this.type = LeaderboardType.THIS_MONTH;
                        this._reload = true;
                        this._indicesOfWidgetsToExpand = [];
                    });
                  },
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    'This month',
                    style: TextStyle(fontSize: 17)
                  ),
                  color: this.type == LeaderboardType.THIS_MONTH ? mainRed : secondaryBlack,
                  splashColor: mainRed,
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<User>>(
            future: () async {
              int fromTime;
              int toTime = DateTime.now().millisecondsSinceEpoch;
              if (this.type == LeaderboardType.TODAY) {
                fromTime = DateTimeHelper.lastMidnight().millisecondsSinceEpoch;
              } else if (this.type == LeaderboardType.THIS_WEEK) {
                fromTime = DateTimeHelper.beginningOfWeek().millisecondsSinceEpoch;
              } else if (this.type == LeaderboardType.THIS_MONTH) {
                fromTime = DateTimeHelper.beginningOfMonth().millisecondsSinceEpoch;
              }
              return await apiClient.fetchTopUsers(
                fromTime,
                toTime,
              );
            }(),
            builder: (BuildContext context, AsyncSnapshot<List<User>> snapshot) {
              if (snapshot.hasData && !(_reload && !(snapshot.connectionState == ConnectionState.done))) {
                return Scrollbar(
                  child: ListView.builder(
                    itemCount: snapshot.data.length,
                    itemBuilder: (BuildContext context, int index) {
                      User user = snapshot.data[index];
                      int hrs = user.playDuration.inHours;
                      int mins = user.playDuration.inMinutes % 60;
                      int secs = user.playDuration.inSeconds % 60;
                      return InkWell(
                        child: Container(
                          margin: EdgeInsets.fromLTRB(10, 20, 15, 5),
                          child: ClipRRect(
                            child: Column(
                              children: [
                                Container(
                                  height: 80,
                                  padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                                  color: tertiaryBlack,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(user.username, overflow: TextOverflow.ellipsis, style: highlightedTextStyle,),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (hrs > 0) Text(hrs.toString() + ' hrs', style: TextStyle(color: secondaryBlack)),
                                          if (mins > 0) Text(mins.toString() + ' mins', style: TextStyle(color: secondaryBlack)),
                                          if (secs > 0) Text(secs.toString() + ' secs', style: TextStyle(color: secondaryBlack)),
                                        ]
                                      ),
                                    ]
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.fromLTRB(5, 5, 10, 5),
                                  height: _indicesOfWidgetsToExpand.contains(index) ? 190 / 3 * user.topTracks.length : 0,
                                  color: tertiaryBlack,
                                  child: Column(
                                    children: [
                                      for (Track track in user.topTracks.keys) Container(
                                        child: HorizontalMusicEntryWidget.fromTrack(track, playDuration: user.topTracks[track]),
                                        padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
                                      ),
                                    ]
                                  ),
                                ),
                              ]
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                              _reload = false;
                              if (_indicesOfWidgetsToExpand.contains(index)) {
                              _indicesOfWidgetsToExpand.remove(index);
                              } else {
                                _indicesOfWidgetsToExpand.add(index);
                              }
                          });
                        }
                      );
                    }
                  ),
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }
          )
        ),
      ],
    );
  }
}
