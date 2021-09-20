import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:trackify_android/api/api.dart';
import 'package:trackify_android/db/models.dart';
import 'package:trackify_android/config.dart';
import 'package:trackify_android/widgets/widgets.dart';
import 'package:trackify_android/widgets/general_widgets.dart';

class VerticalMusicEntryWidget extends StatelessWidget {
  String imageUrl;
  String title;
  String subTitle;
  String info;
  bool showText = true;

  VerticalMusicEntryWidget(this.imageUrl, this.title, this.subTitle, this.info, {this.showText});

  static VerticalMusicEntryWidget fromTrack(Track track, {Duration playDuration: null, bool showText=true}) {
    if (playDuration == null) {
      return VerticalMusicEntryWidget(track.album.largeCover.url, track.name, track.artists[0].name, null, showText: showText);
    }
    int hrs = playDuration.inHours;
    int mins = playDuration.inMinutes % 60;
    int secs = playDuration.inSeconds % 60;
    return VerticalMusicEntryWidget(track.album.largeCover.url, track.name, track.artists[0].name,
      (hrs > 0 ? hrs.toString() + ' hrs ' : '') +
      (mins > 0 ? mins.toString() + ' mins ' : '') +
      (secs > 0 ? secs.toString() + ' secs ' : ''),
      showText: showText
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
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
                  Text(
                    //this.title.replaceAll(' ', '\u00A0'),
                    this.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(color: mainRed, fontSize: 13),
                  ),
                  if (this.subTitle != null) Text(
                    this.subTitle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(color: secondaryBlack, fontSize: 13)
                  ),
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
        return HorizontalMusicEntryWidget(track.album.smallCover.url, track.name, track.artists[0].name, null);
    int hrs, mins, secs;
    if (playDuration != null) {
      hrs = playDuration.inHours;
      mins = playDuration.inMinutes % 60;
      secs = playDuration.inSeconds % 60;
    }
    return HorizontalMusicEntryWidget(track.album.smallCover.url, track.name, track.artists[0].name, Column(
      children: [
        if (hrs > 0) Text(hrs.toString() + ' hrs', style: TextStyle(color: secondaryBlack)),
        if (mins > 0) Text(mins.toString() + ' mins', style: TextStyle(color: secondaryBlack)),
        if (secs > 0) Text(secs.toString() + ' secs', style: TextStyle(color: secondaryBlack)),
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
                    width: 140,
                    margin: EdgeInsets.fromLTRB(10, 0, 10, 5),
                    child: VerticalMusicEntryWidget.fromTrack(this.tracks.keys.elementAt(i), playDuration: this.tracks.values.elementAt(i)),
                  ), onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TrackHistoryWidget(this.tracks.keys.elementAt(i))),
                    );
                }),
              ],
          ), height: 220)
        ],
      ),
      color: Colors.transparent);
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
      title: Text(widget.title, style: TextStyle(color: mainBlack, fontSize: 21)),
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
              itemCount: widget.tracks.keys.length % _tracksPerRow > 0 ? widget.tracks.keys.length ~/ _tracksPerRow + 1 : widget.tracks.keys.length ~/ _tracksPerRow,
              itemBuilder: (BuildContext context, int index) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: index * _tracksPerRow + _tracksPerRow < widget.tracks.keys.length ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.start,
                  children: [
                    for (int i = index * _tracksPerRow; i < index * _tracksPerRow + _tracksPerRow; ++i) Flexible(
                      child: InkWell(
                        child: Container(
                          padding: EdgeInsets.all(2),
                          child: i < widget.tracks.keys.length ? VerticalMusicEntryWidget.fromTrack(widget.tracks.keys.elementAt(i),
                            playDuration: widget.tracks.values.elementAt(i),
                            showText: _showInfo,
                          ) : Container(width: 500, color: mainRed),
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

class HistoryWidget extends StatefulWidget {
  APIClient apiClient;
  DateTime firstPlayDateTime;

  HistoryWidget(this.apiClient, this.firstPlayDateTime);

  @override
  State<HistoryWidget> createState() => HistoryWidgetState(this.apiClient, this.firstPlayDateTime);
}

class HistoryWidgetState extends State<HistoryWidget> {
  final ItemScrollController _scrollController = ItemScrollController();

  APIClient apiClient;
  DateTime firstPlayDateTime;
  int currentMonthIdx = -1;

  HistoryWidgetState(this.apiClient, this.firstPlayDateTime);

  @override
  Widget build(BuildContext context) {
    DateTime lastPlayDateTime = this.apiClient.data.lastPlayDateTime();
    List<DateTime> months = [];
    DateTime firstMonth = DateTime(firstPlayDateTime.year, firstPlayDateTime.month);
    for (DateTime m = firstMonth; m.isBefore(lastPlayDateTime); m = DateTime(m.year, m.month + 1)) {
      months.add(m);
    }
    if (currentMonthIdx == -1) {
      currentMonthIdx = months.length - 1;
    }
    DateTime month = months[currentMonthIdx];
    return Column(
      children: [
        SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: mainBlack),
                tooltip: "previous",
                onPressed: () {
                  setState(() {
                      if (currentMonthIdx > 0) {
                        currentMonthIdx = currentMonthIdx - 1;
                      }
                  });
                },
              ),
              Text(DateFormat('MMMM y').format(month)),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios, color: mainBlack),
                tooltip: "next",
                onPressed: () {
                  setState(() {
                      if (currentMonthIdx < months.length - 1) {
                        currentMonthIdx = currentMonthIdx + 1;
                      }
                  });
                },
              ),
            ]
          )
        ),
        Expanded(
          child: FutureBuilder<APIData>(
            future: () async {
              return await this.apiClient.getData(month, DateTime(month.year, month.month + 1));
            }(),
            builder: (BuildContext context, AsyncSnapshot<APIData> snapshot) {
              if (snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
                APIData data = snapshot.data;
                List<Play> sortedPlays = data.sortedPlays();
                List<DateTime> days = [];
                List<dynamic> rowData = [];
                for (Play play in sortedPlays) {
                  DateTime playTime = play.startDateTime();
                  DateTime day = DateTime(playTime.year, playTime.month, playTime.day);
                  if (!days.contains(day)) {
                    days.add(day);
                    rowData.add(day);
                  }
                  rowData.add(play);
                }

                return Row(
                  children: [
                    Expanded(
                      child: ScrollablePositionedList.builder(
                        itemScrollController: _scrollController,
                        itemCount: rowData.length,
                        itemBuilder: (BuildContext context, int index) {
                          print('${index}/${rowData.length}');
                          dynamic data = rowData[index];
                          if (data is DateTime) {
                            return Container(
                              padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                              child: Text("${rowData[index].day}/${rowData[index].month}"),
                            );
                          } else if (data is Play) {
                            return Container(
                              padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                              child: HorizontalMusicEntryWidget.fromTrack(rowData[index].track),
                            );
                          }
                        }
                      ),
                    ),
                    Container(
                      width: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Reference', style: TextStyle(color: mainRed)),
                          Expanded(
                            child: ListView.builder(
                              itemCount: days.length,
                              itemBuilder: (BuildContext context, int index) {
                                DateTime day = days[index];
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    child: Center(
                                      child: Text("${day.day}/${day.month}"),
                                    ),
                                    onTap: () {
                                      int idx = 0;
                                      for (dynamic data in rowData) {
                                        if (data is DateTime) {
                                          if (data.isAtSameMomentAs(day)) {
                                            _scrollController.scrollTo(
                                              index: idx,
                                              duration: Duration(seconds: 1),
                                              curve: Curves.easeInOutCubic
                                            );
                                            break;
                                          }
                                        }
                                        idx++;
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                );
              } else {
                  return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ],
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
                        child: Image.network(this.track.album.largeCover.url, fit: BoxFit.contain),
                        padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                ))]),
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
                      Text(DateFormat('dd/MM/yyyy HH:mm:ss a').format(play.startDateTime()), style: TextStyle(color: mainRed)),
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

class LibraryWidget extends StatefulWidget {
  APIClient apiClient;

  LibraryWidget(this.apiClient, Key key) : super(key: key);

  State<LibraryWidget> createState() => LibraryWidgetState(this.apiClient);
}

class LibraryWidgetState extends State<LibraryWidget> {
  APIClient apiClient;

  LibraryWidgetState(this.apiClient);

  final TextEditingController _controller = TextEditingController();

  void beginAddCollage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color.fromRGBO(70, 70, 70, 1),
          title: Text('Enter collage name'),
          content: TextField(
            autofocus: true,
            onChanged: (value) {
            },
            controller: _controller,
            decoration: InputDecoration(
              hintText: "collage name",
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: mainRed, width: 5.0)),
            ),
            cursorColor: mainRed,
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel', style: TextStyle(color: Colors.black)),
              onPressed: () {
                _controller.text = "";
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text('Ok', style: TextStyle(color: Colors.black)),
              onPressed: () async {
                if (_controller.text != "") {
                  await this.apiClient.addCollage(_controller.text);
                  Navigator.pop(context);
                  setState(() {});
                  _controller.text = "";
                }
              },
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: this.apiClient.data.collages.keys.length,
      itemBuilder: (BuildContext context, int index) {
        Collage collage = this.apiClient.data.collages.values.elementAt(index);
        return Container(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    child: collage.tracks.length > 0 ? Image.network(
                      collage.tracks[0].album.smallCover.url,
                      fit: BoxFit.contain,
                    ) : PlaceholderImage(),
                    width: 55,
                    height: 55,
                  ),
                  Container(width: 5),
                  Text(collage.name, style: TextStyle(fontSize: 17)),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CollageWidget(collage, this.apiClient, this.setState),
                  ),
                );
              }
            )
          ),
          padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
        );
      }
    );
  }
}

class CollageWidget extends StatefulWidget {
  Collage collage;
  APIClient apiClient;
  Function libraryWidgetSetState;

  CollageWidget(this.collage, this.apiClient, this.libraryWidgetSetState);

  State<CollageWidget> createState() => CollageWidgetState(this.collage, this.apiClient, this.libraryWidgetSetState);
}

enum CollageControlType {
  add_track, remove_track, rename_collage, delete_collage
}

class CollageWidgetState extends State<CollageWidget> {
  Collage collage;
  APIClient apiClient;
  Function libraryWidgetSetState;

  CollageWidgetState(this.collage, this.apiClient, this.libraryWidgetSetState);

  @override
  Widget build(BuildContext context) {
    int _tracksPerRow = 3;
    return GeneralPage(
      title: Text(collage.name, style: TextStyle(color: mainBlack, fontSize: 21)),
      controls: PopupMenuButton(
        icon: Icon(Icons.more_vert, color: mainBlack),
        color: secondaryBlack,
        onSelected: (CollageControlType controlType) {
          if (controlType == CollageControlType.add_track) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackSearchBar(
                  this.apiClient.data.tracks.values,
                  (Track track) async {
                    await this.apiClient.addTrackToCollage(this.collage, track);
                    this.libraryWidgetSetState(() {});
                    setState(() {});
                  },
                ),
              ),
            );
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<CollageControlType>>[
          PopupMenuItem<CollageControlType>(
            value: CollageControlType.add_track,
            child: Row(
              children: [
                Icon(Icons.add_circle, color: mainBlack),
                Container(width: 3),
                Text('add track', style: TextStyle(color: mainBlack)),
              ],
            ),
          ),
          PopupMenuItem<CollageControlType>(
            value: CollageControlType.remove_track,
            child: Row(
              children: [
                Icon(Icons.remove_circle, color: mainBlack),
                Container(width: 3),
                Text('remove track', style: TextStyle(color: mainBlack)),
              ],
            ),
          ),
          PopupMenuItem<CollageControlType>(
            value: CollageControlType.rename_collage,
            child: Row(
              children: [
                Icon(Icons.edit, color: mainBlack),
                Container(width: 3),
                Text('rename collage', style: TextStyle(color: mainBlack)),
              ],
            ),
          ),
          PopupMenuItem<CollageControlType>(
            value: CollageControlType.delete_collage,
            child: Row(
              children: [
                Icon(Icons.delete, color: mainBlack),
                Container(width: 3),
                Text('delete collage', style: TextStyle(color: mainBlack)),
              ],
            ),
          ),
        ],    
      ),
      content: ListView.builder(
        itemCount: collage.tracks.length % _tracksPerRow > 0 ? collage.tracks.length ~/ _tracksPerRow + 1 : collage.tracks.length ~/ _tracksPerRow,
        itemBuilder: (BuildContext context, int index) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: index * _tracksPerRow + _tracksPerRow < collage.tracks.length ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.start,
            children: [
              for (int i = index * _tracksPerRow; i < index * _tracksPerRow + _tracksPerRow; ++i) Flexible(
                child: InkWell(
                  child: Container(
                    padding: EdgeInsets.all(2),
                    child: i < collage.tracks.length ? VerticalMusicEntryWidget.fromTrack(collage.tracks.elementAt(i)) : Container(width: 500),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TrackHistoryWidget(collage.tracks.elementAt(i))),
                    );
                  },
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}

class TrackSearchBar extends StatefulWidget {
  Iterable<Track> tracks;
  Function onSelect;

  TrackSearchBar(this.tracks, this.onSelect);

  State<TrackSearchBar> createState() => TrackSearchBarState(this.tracks, this.onSelect);
}

class TrackSearchBarState extends State<TrackSearchBar> {
  Iterable<Track> tracks;
  String query = "";
  Function onSelect;

  TrackSearchBarState(this.tracks, this.onSelect);

  @override
  Widget build(BuildContext context) {
    List<Track> tracksThatMatch = [];
    if (query != "") {
      for (Track track in this.tracks) {
        if (track.name.toLowerCase().contains(this.query.toLowerCase())) {
          tracksThatMatch.add(track);
          continue;
        }
        bool found = false;
        for (Artist artist in track.artists) {
          if (artist.name.toLowerCase().contains(this.query.toLowerCase())) {
            tracksThatMatch.add(track);
            found = true;
            break;
          }
        }
        if (found) {
          continue;
        }
        if (track.album.name.toLowerCase().contains(this.query.toLowerCase())) {
          tracksThatMatch.add(track);
          continue;
        }
      }
    }
    return MainContainerWidget(
      child: Column(
        children: [
          Container(
            color: secondaryBlack,
            child: Row(
              children: [
                Icon(Icons.search, color: mainBlack),
                Container(width: 5),
                Expanded(
                  child: TextField(
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {
                          this.query = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "track title",
                      border: InputBorder.none,
                    ),
                    cursorColor: mainRed,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: mainBlack,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  }
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tracksThatMatch.length,
              itemBuilder: (BuildContext _, int index) {
                Track track = tracksThatMatch[index];
                return InkWell(
                  child: Container(
                    child: HorizontalMusicEntryWidget.fromTrack(track),
                    padding: EdgeInsets.fromLTRB(5, 3, 5, 0),
                  ),
                  onTap: () {
                    onSelect(track);
                    Navigator.pop(context);
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
