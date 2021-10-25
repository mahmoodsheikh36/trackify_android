import 'package:flutter/material.dart';

import 'package:trackify_android/static.dart';
import 'package:trackify_android/ui/route.dart';
import 'package:trackify_android/db/models.dart';
import 'package:trackify_android/ui/widgets/music.dart';
import 'package:trackify_android/ui/widgets/counter.dart';
import 'package:trackify_android/ui/widgets/generic_route_filler.dart';

class TrackListRoute extends MyRoute {
  String title;
  Map<Track, Duration> tracks;
  
  TrackListRoute({this.title, this.tracks}) : super(path: '/track_list');

  Widget buildWidget(BuildContext context) {
    return TrackListRouteWidget(title: this.title, tracks: this.tracks);
  }
}

class TrackListRouteWidget extends StatefulWidget {
  Map<Track, Duration> tracks;
  String title;

  TrackListRouteWidget({this.title, this.tracks});

  @override
  State<TrackListRouteWidget> createState() => TrackListRouteWidgetState();
}

class TrackListRouteWidgetState extends State<TrackListRouteWidget> {
  int _tracksPerRow = 3;
  bool _showInfo = true;

  @override
  Widget build(BuildContext context) {
    return GenericRouteFiller(
      title: Text(widget.title, style: TextStyle(color: mainBlack, fontSize: 21)),
      child: Column(
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
                          //Navigator.push(
                          //  context,
                          //  MaterialPageRoute(builder: (context) => TrackHistoryWidget(widget.tracks.keys.elementAt(i))),
                          //);
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
