import 'package:flutter/material.dart';

import 'package:trackify_android/static.dart';
import 'package:trackify_android/db/models.dart';
import 'package:trackify_android/ui/router.dart';
import 'package:trackify_android/ui/widgets/music.dart';
import 'package:trackify_android/ui/widgets/counter.dart';
import 'package:trackify_android/ui/routes/music/track_list.dart';

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
                        router.pushRoute(
                          TrackListRoute(title: this.title, tracks: this.tracks)
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
                    //Navigator.push(
                    //  context,
                    //  MaterialPageRoute(builder: (context) => TrackHistoryWidget(this.tracks.keys.elementAt(i))),
                    //);
                }),
              ],
          ), height: 220)
        ],
      ),
      color: Colors.transparent);
  }
}
