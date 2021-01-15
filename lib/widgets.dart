import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:trackify_android/config.dart';
import 'package:trackify_android/api.dart';

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

class VerticalMusicEntryWidget extends StatelessWidget {
  String imageUrl;
  String title;
  String subTitle;
  String info;
  bool showText = true;

  VerticalMusicEntryWidget(this.imageUrl, this.title, this.subTitle, this.info, {this.showText});

  static VerticalMusicEntryWidget fromTrack(Track track, {Duration playDuration: null, bool showText=true}) {
    int hrs, mins, secs;
    if (playDuration == null) {
      hrs = (track.msPlayed() / 1000 / 60 / 60).toInt();
      mins = ((track.msPlayed() / 1000 / 60) % 60).toInt();
      secs = ((track.msPlayed() / 1000) % 60).toInt();
    } else {
      hrs = playDuration.inHours;
      mins = playDuration.inMinutes % 60;
      secs = playDuration.inSeconds % 60;
    }
    return VerticalMusicEntryWidget(track.album.covers[1].url, track.name, track.artists[0].name,
      (hrs > 0 ? hrs.toString() + ' hrs ' : '') +
      (mins > 0 ? mins.toString() + ' mins ' : '') +
      (secs > 0 ? secs.toString() + ' secs ' : ''),
      showText: showText
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      child: Column(
        children: <Widget>[
          Container(
            child: Image.network(
              this.imageUrl,
              frameBuilder: (BuildContext context, Widget child, int frame, bool wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) {
                  return child;
                }
                return AnimatedOpacity(
                  child: child,
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeOut,
                );
              },
              fit: BoxFit.contain,
            )
          ),
          if (this.showText) Column(
            children: [
              SizedBox(height: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(this.title.replaceAll(' ', '\u00A0'), overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(color: mainRed)),
                  if (this.subTitle != null) Text(this.subTitle, overflow: TextOverflow.ellipsis, style: TextStyle(color: secondaryBlack)),
                  if (this.info != null) Text(
                    this.info,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: secondaryBlack, fontSize: 12)
                  ),
                ],
              ),
            ]
          )
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}

class HorizontalMusicEntryWidget extends StatelessWidget {
  String imageUrl;
  String title;
  String subTitle;
  Widget info;

  HorizontalMusicEntryWidget(this.imageUrl, this.title, this.subTitle, this.info);

  static HorizontalMusicEntryWidget fromTrack(Track track, {Duration playDuration=null}) {
    if (playDuration == null)
        return HorizontalMusicEntryWidget(track.album.covers[0].url, track.name, track.artists[0].name, null);
    int hrs, mins, secs;
    if (playDuration != null) {
      hrs = playDuration.inHours;
      mins = playDuration.inMinutes % 60;
      secs = playDuration.inSeconds % 60;
    }
    return HorizontalMusicEntryWidget(track.album.covers[0].url, track.name, track.artists[0].name, Column(
      children: [
        Text(hrs.toString() + ' hrs', style: TextStyle(color: secondaryBlack)),
        Text(mins.toString() + ' mins', style: TextStyle(color: secondaryBlack)),
        Text(secs.toString() + ' secs', style: TextStyle(color: secondaryBlack)),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(child: Container(
      color: tertiaryBlack,
      child: Row(children: <Widget>[
        Container(
          margin: const EdgeInsets.all(4),
          child: Image.network(
            this.imageUrl,
            width: 45,
            height: 45,
            fit: BoxFit.contain,
          )
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              this.subTitle != null
                ? Flexible(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(this.title, overflow: TextOverflow.ellipsis, style: TextStyle(color: mainRed)),
                      SizedBox(height: 5,),
                      Text(this.subTitle, overflow: TextOverflow.ellipsis, style: TextStyle(color: secondaryBlack)),
                  ])) : Text(this.title),
              if (this.info != null) Container(
                child: this.info,
                padding: EdgeInsets.fromLTRB(0, 0, 5, 0),
              ),
            ]
          )
        )
      ]),
    ), borderRadius: BorderRadius.circular(7),);
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

class AfterAuthWidget extends StatefulWidget {
  final APIClient apiClient;

  AfterAuthWidget(this.apiClient);
  
  @override
  State<StatefulWidget> createState() => AfterAuthWidgetState(this.apiClient);
}

class AfterAuthWidgetState extends State<AfterAuthWidget> {
  int _bottomNavigationBarIndex = 0;
  PageController _pageController;
  Future<APIData> _future;
  APIClient apiClient;

  AfterAuthWidgetState(this.apiClient) {
    _future = () async {
      return await this.apiClient.fetchThisMonthData();
    }();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _bottomNavigationBarOnTap(int index) {
    setState(() {
      _pageController.animateToPage(index,
        duration: Duration(milliseconds: 250), curve: Curves.easeOut);
      _bottomNavigationBarIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<APIData>(
      future: this._future,
      builder: (BuildContext context, AsyncSnapshot<APIData> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        } else {
          return SafeArea(
            child: Scaffold(
              //backgroundColor: mainBlack,
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: mainRed, width: 2)),
                ),
                child: BottomNavigationBar(
                  selectedItemColor: mainRed,
                  backgroundColor: mainBlack,
                  unselectedItemColor: secondaryBlack,
                  items: [
                    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
                    BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
                  ],
                  onTap: this._bottomNavigationBarOnTap,
                  currentIndex: this._bottomNavigationBarIndex,
                )
              ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: FractionalOffset.topRight,
                    end: FractionalOffset.bottomLeft,
                    colors: [
                      Color.fromRGBO(150, 93, 93, 1),
                      mainBlack,
                      mainBlack,
                    ],
                  ),
                ),
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
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: Text("Trackify", style: TextStyle(color: mainBlack, fontSize: 21)),
                            )
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Material( // to make iconbutton splash appear above parent
                              type: MaterialType.transparency, // ^
                              child: IconButton(
                                icon: Icon(Icons.settings),
                                tooltip: "settings",
                                onPressed: () {
                                  print('settings button pressed');
                                },
                              ),
                            )
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _bottomNavigationBarIndex = index);
                        },
                        children: <Widget>[
                          HomeWidget(snapshot.data),
                          HistoryWidget(snapshot.data),
                          LeaderboardWidget(this.apiClient),
                        ],
                    ))
                  ]
                ),
              ),
            )
          );
        }
      }
    );
  }
}

class HomeWidget extends StatelessWidget {
  final APIData apiData;
  Map<Track, Duration> topTracksToday;
  Map<Track, Duration> topTracksThisWeek;
  Map<Track, Duration> topTracksThisMonth;
  List<Track> randomTracks;

  HomeWidget(this.apiData) {
    topTracksToday = apiData.topTracksToday();
    topTracksThisWeek = apiData.topTracksThisWeek();
    topTracksThisMonth = apiData.topTracksThisMonth();
    randomTracks = apiData.getRandomTracks(4);
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
          Container(child: Row(
              children: [
                Expanded(child: HorizontalMusicEntryWidget.fromTrack(randomTracks[0])),
                SizedBox(width: 5),
                Expanded(child: HorizontalMusicEntryWidget.fromTrack(randomTracks[1])),
              ],
            ), padding: EdgeInsets.fromLTRB(10, 0, 10, 5)),
          Container(child: Row(
              children: [
                Expanded(child: HorizontalMusicEntryWidget.fromTrack(randomTracks[2])),
                SizedBox(width: 5),
                Expanded(child: HorizontalMusicEntryWidget.fromTrack(randomTracks[3])),
              ],
            ), padding: EdgeInsets.fromLTRB(10, 0, 10, 5)),
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

class HorizontalTrackListWidget extends StatelessWidget {
  String title;
  Map<Track, Duration> tracks;

  HorizontalTrackListWidget({this.title, this.tracks});
  
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: mainRed, fontSize: 21)),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrackListWidget(
                              title: this.title,
                              tracks: this.tracks,
                            )
                          ),
                        );
                      },
                      child: Container(
                        child: Row(
                          children: [
                            Text('View more ', style: TextStyle(color: Colors.black, fontSize: 15)),
                            Icon(Icons.arrow_forward_ios, size: 17),
                          ]
                        ),
                        padding: EdgeInsets.all(7)
                      ),
                    ),
                  ]
                )
              ],
            ),
            padding: EdgeInsets.fromLTRB(15, 30, 0, 5),
          ),
          Container(child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (int i = 0; i < this.tracks.keys.length && i < 10; ++i) InkWell(child: Container(
                    child: VerticalMusicEntryWidget.fromTrack(this.tracks.keys.elementAt(i), playDuration: this.tracks.values.elementAt(i)),
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 5),
                  ), onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TrackHistoryWidget(this.tracks.keys.elementAt(i))),
                    );
                }),
              ],
          ), height: 200)
        ],
      ),
      color: Colors.transparent);
  }
}

class CounterWidget extends StatefulWidget {
  int count;
  Function onChange;

  CounterWidget({this.count=0, this.onChange});
  
  @override
  State<CounterWidget> createState() => CounterWidgetState();
}

class CounterWidgetState extends State<CounterWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.remove, size: 21, color: mainRed),
          tooltip: "decrement",
          onPressed: () {
            if (widget.count > 1) {
              setState(() {
                  widget.count -= 1;
                  widget.onChange(widget.count);
              });
            }
          },
        ),
        Text(widget.count.toString(), style: TextStyle(color: secondaryBlack, fontSize: 20)),
        IconButton(
          icon: Icon(Icons.add, size: 21, color: mainRed),
          tooltip: "increment",
          onPressed: () {
            setState(() {
                widget.count += 1;
                widget.onChange(widget.count);
            });
          },
        ),
      ]
    );
  }
}

class TrackListWidget extends StatefulWidget {
  Map<Track, Duration> tracks;
  String title;

  TrackListWidget({this.title, this.tracks});

  @override
  State<TrackListWidget> createState() => TrackListWidgetState();
}

class TrackListWidgetState extends State<TrackListWidget> {
  int _tracksPerRow = 3;
  bool _showInfo = true;

  @override
  Widget build(BuildContext context) {
    return GeneralPage(
      title: Text(widget.title, style: TextStyle(color: mainRed, fontSize: 21)),
      content: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(width: 10),
                  Text('columns', style: TextStyle(color: secondaryBlack, fontSize: 18)),
                  CounterWidget(count: _tracksPerRow, onChange: (int count) {
                      setState(() {
                          _tracksPerRow = count;
                      });
                  }),
                ]
              ),
              Row(
                children: [
                  Text('info', style: TextStyle(color: secondaryBlack, fontSize: 18)),
                  Switch(
                    activeColor: mainRed,
                    value: _showInfo,
                    onChanged: (value) {
                      setState(() {
                          _showInfo = value;
                      });
                    },
                  ),
                  SizedBox(width: 10),
                ]
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.tracks.keys.length % _tracksPerRow == 1 ? widget.tracks.keys.length ~/ _tracksPerRow + 1 : widget.tracks.keys.length ~/ _tracksPerRow,
              itemBuilder: (BuildContext context, int index) {
                return Row(
                  mainAxisAlignment: index * _tracksPerRow + _tracksPerRow < widget.tracks.keys.length ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.start,
                  children: [
                    for (int i = index * _tracksPerRow; i < index * _tracksPerRow + _tracksPerRow && i < widget.tracks.keys.length; ++i) Flexible(
                      child: InkWell(
                        child: Container(
                          padding: EdgeInsets.all(2),
                          child: VerticalMusicEntryWidget.fromTrack(widget.tracks.keys.elementAt(i),
                            playDuration: widget.tracks.values.elementAt(i),
                            showText: _showInfo,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TrackHistoryWidget(widget.tracks.keys.elementAt(i))),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
            )
          ),
        ]
      ),
    );
  }
}

enum HistoryEntryType {
  TITLE, PLAY
}

class HistoryWidget extends StatelessWidget {
  APIData apiData;
  Future<List<MapEntry<dynamic, HistoryEntryType>>> _future;

  HistoryWidget(this.apiData) {
    this._future = () async {
      var history = this.apiData.sortedPlays();
      List<MapEntry<dynamic, HistoryEntryType>> entries = [];
      for (Play play in history) {
        String title;
        DateTime now = DateTime.now();
        DateTime startTime = play.startDateTime();
        if (DateTime(startTime.year, startTime.month, startTime.day) == DateTime(now.year, now.month, now.day)) {
          title = "Today";
        } else if (DateTime(startTime.year, startTime.month, startTime.day) == DateTime(now.year, now.month, now.day - 1)) {
          title = "Yesterday";
        } else {
          title = startTime.day.toString() + "/" + startTime.month.toString() + "/" + startTime.year.toString();
        }
        bool titleExists = false;
        for (MapEntry entry in entries) {
          if (entry.key == title) {
            titleExists = true;
          }
        }
        if (!titleExists) {
          entries.add(MapEntry(title, HistoryEntryType.TITLE));
        }
        entries.add(MapEntry(play, HistoryEntryType.PLAY));
      }
      return entries;
    }();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MapEntry<dynamic, HistoryEntryType>>>(
      future: this._future,
      builder: (BuildContext context, AsyncSnapshot<List<MapEntry<dynamic, HistoryEntryType>>> snapshot) {
        if (snapshot.hasData) {
          return Scrollbar(
            child: ListView.builder(
              key: new PageStorageKey('historyListView'),
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                List<MapEntry<dynamic, HistoryEntryType>> entries = snapshot.data;
                MapEntry<dynamic, HistoryEntryType> entry = entries[index];
                if (entry.value == HistoryEntryType.TITLE) {
                  return Container(
                    child: Center(
                      child: Text(entry.key, style: TextStyle(color: mainRed, fontSize: 21)),
                    ),
                    padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                  );
                } else if (entry.value == HistoryEntryType.PLAY){
                  return Container(
                    child: HorizontalMusicEntryWidget.fromTrack(entry.key.track),
                    padding: EdgeInsets.fromLTRB(25, 10, 25, 0),
                  );
                }
              },
            ),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      }
    );
  }
}

enum LeaderboardType {
  TODAY, THIS_WEEK, THIS_MONTH
}

class LeaderboardWidget extends StatefulWidget {
  final APIClient apiClient;

  LeaderboardWidget(this.apiClient);
  
  @override
  State<StatefulWidget> createState() => LeaderboardWidgetState(this.apiClient);
}

class LeaderboardWidgetState extends State<LeaderboardWidget> {
  APIClient apiClient;
  LeaderboardType type = LeaderboardType.TODAY;
  List<int> _indicesOfWidgetsToExpand = [];
  bool _reload = true;

  LeaderboardWidgetState(this.apiClient);

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
              return await this.apiClient.fetchTopUsers(
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
                                  height: _indicesOfWidgetsToExpand.contains(index) ? 185 : 0,
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

class AuthWidget extends StatefulWidget {
  final APIClient apiClient;
  bool registerNotLogin = true;
  final RootWidgetState rootWidgetState;

  AuthWidget(this.apiClient, this.rootWidgetState);

  @override
  State<StatefulWidget> createState() => AuthWidgetState();
}

class AuthWidgetState extends State<AuthWidget> {
  bool registerNotLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: registerNotLogin ? RegisterWidget(widget.apiClient, this) :
      LoginWidget(widget.apiClient, this, () { widget.rootWidgetState.setState(() { }); }));
  }
}

class RegisterWidget extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final APIClient apiClient;
  final AuthWidgetState authWidgetState;

  RegisterWidget(this.apiClient, this.authWidgetState);

  @override
  Widget build(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    return Form(
      key: _formKey,
      child: SafeArea(child: Scaffold(
        backgroundColor: mainBlack,
        body: Container(child: ListView(
          children: <Widget>[
            TextFormField(
              validator: (String username) {
                return validateUsernameInput(username);
              },
              controller: usernameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'enter username',
                hintStyle: TextStyle(color: secondaryBlack),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: mainRed)
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.white),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              validator: (String password) {
                return validatePasswordInput(password);
              },
              obscureText: true,
              controller: passwordController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'enter password',
                hintStyle: TextStyle(color: secondaryBlack),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: mainRed)
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.white),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              validator: (String confirmationPassword) {
                if (passwordController.text != confirmationPassword) {
                  return 'passwords dont match';
                }
                return null;
              },
              obscureText: true,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'confirm password',
                hintStyle: TextStyle(color: secondaryBlack),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: mainRed)
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.white),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              validator: (String email) {
                return validateEmailInput(email);
              },
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'enter email',
                hintStyle: TextStyle(color: secondaryBlack),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: mainRed)
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.white),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            SizedBox(height: 20),
            Align(child: FormButton('Register', () async {
              if (_formKey.currentState.validate()) {
                Scaffold.of(context).showSnackBar(
                  SnackBar(content: Text('communicating with server..'))
                );
                bool success = await this.apiClient.register(usernameController.text,
                                                             passwordController.text,
                                                             emailController.text);
                if (success)
                  print('success in registeration');
                else
                  print('no success in registeration');
              }
            }), alignment: Alignment.center,),
            SizedBox(height: 20,),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('already have an account?', style: highlightedTextStyle),
              TextButton(onPressed: () {
                this.authWidgetState.registerNotLogin = false;
                this.authWidgetState.setState(() { });
              }, child: Text('login'))
            ],)
          ],
        ), margin: EdgeInsets.all(20),),
      )),
    );
  }
}

class LoginWidget extends StatelessWidget {
  final APIClient apiClient;
  final _formKey = GlobalKey<FormState>();
  final AuthWidgetState authWidgetState;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final VoidCallback onAuthDone;

  LoginWidget(this.apiClient, this.authWidgetState, this.onAuthDone);

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(
      backgroundColor: mainBlack,
      body: Form(
        key: _formKey,
        child: Container(child: ListView(
          children: <Widget>[
            TextFormField(
              validator: (String username) {
                return validateUsernameInput(username);
              },
              controller: usernameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'enter username',
                hintStyle: TextStyle(color: secondaryBlack),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: mainRed)
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.white),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            SizedBox(height: 20,),
            TextFormField(
              validator: (String password) {
                return validatePasswordInput(password);
              },
              obscureText: true,
              controller: passwordController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'enter password',
                hintStyle: TextStyle(color: secondaryBlack),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: mainRed)
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.white),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            SizedBox(height: 20,),
            Align(child: FormButton('Login', () async {
              if (_formKey.currentState.validate()) {
                Scaffold.of(context).showSnackBar(
                  SnackBar(content: Text('logging in..'))
                );
                bool success = await this.apiClient.authenticate(usernameController.text,
                                                                  passwordController.text);
                if (success) {
                  this.apiClient.isAuthDone();
                  this.onAuthDone();
                } else {
                  print('no success in authentication');
                }
              } else {
                print('login form not valid');
              }
            }), alignment: Alignment.center,),
            SizedBox(height: 20,),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('dont have an account?', style: highlightedTextStyle,),
              TextButton(onPressed: () {
                this.authWidgetState.registerNotLogin = true;
                this.authWidgetState.setState(() { });
              }, child: Text('register'))
            ],)
          ],
        ), margin: EdgeInsets.all(20),),
      ),
    ));
  }
}

class FormTextField extends StatefulWidget {
  final String hintText;
  final FormFieldValidator<String> validator;
  final bool isPassword;
  String text;

  String getText() {
    return this.text;
  }

  FormTextField(this.hintText, this.validator, {this.isPassword = false});

  @override
  State<StatefulWidget> createState() {
    return FormTextFieldState(this.hintText, this.validator, (String newValue) { text = newValue; getText(); }, isPassword: this.isPassword);
  }
}

class FormTextFieldState extends State<FormTextField> {
  final String hintText;
  final FormFieldValidator<String> validator;
  final bool isPassword;
  final ValueChanged<String> onChange;

  FormTextFieldState(this.hintText, this.validator, this.onChange, {this.isPassword = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: TextFormField(
        onChanged: this.onChange,
        obscureText: this.isPassword,
        validator: this.validator,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: secondaryBlack),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
            borderSide: BorderSide(color: mainRed)
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
            borderSide: BorderSide(color: Colors.white),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
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

class TrackHistoryWidget extends StatelessWidget {
  Track track;

  TrackHistoryWidget(this.track);

  @override
  Widget build(BuildContext context) {
    return MainContainerWidget(
      child: ListView.builder(
        itemCount: this.track.plays.length + 1,
        itemBuilder: (BuildContext _, int index) {
          if (index == 0) {
            return Column(
              children: [
                SizedBox(height: 10),
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_downward, color: mainRed),
                        tooltip: "close",
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Text(this.track.name, style: highlightedTextStyle),
                          Text(this.track.artists[0].name, style: TextStyle(color: secondaryBlack)),
                        ]
                      ),
                    )
                  ],
                ),
                Row(children: [Expanded(child: Container(
                        child: Image.network(this.track.album.covers[2].url, fit: BoxFit.contain),
                        padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                ))]),
                SizedBox(height: 10),
                Text("Track details", style: highlightedTextStyle),
                Text("total play time: 316 hrs 31 mins", style: TextStyle(color: secondaryBlack)),
                Text("total plays: 716", style: TextStyle(color: secondaryBlack)),
                Text("all time rank: 213", style: TextStyle(color: secondaryBlack)),
              ]
            );
          } else {
            Play play = this.track.plays[index - 1];
            return Container(
              margin: EdgeInsets.fromLTRB(25, 10, 25, 0),
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: tertiaryBlack,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: secondaryBlack),
                      SizedBox(width: 3),
                      Text(play.startDateTime().toString(), style: TextStyle(color: mainRed)),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.play_arrow, color: secondaryBlack),
                      SizedBox(width: 3),
                      Text(
                        (play.durationPlayed().inHours > 0 ? play.durationPlayed().inHours.toString() + " hrs " : "") +
                        (play.durationPlayed().inMinutes > 0 ? play.durationPlayed().inMinutes.toString() + " mins " : "") +
                        (play.durationPlayed().inSeconds > 0 ? play.durationPlayed().inSeconds.toString() + " secs " : ""),
                        style: TextStyle(color: secondaryBlack),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class GeneralPage extends StatelessWidget {
  Widget content;
  Widget title;

  GeneralPage({this.title, this.content});

  @override
  Widget build(BuildContext context) {
    return MainContainerWidget(
      child: Column(
        children: [
          Container(
            height: 50,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_downward, color: mainRed),
                    tooltip: "close",
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: this.title,
                )
              ],
            ),
          ),
          Container(
            height: 2,
            color: mainRed,
          ),
          Expanded(child: this.content),
        ],
      ),
    );
  }
}
