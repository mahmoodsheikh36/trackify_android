import 'package:flutter/material.dart';

import 'package:trackify_android/static.dart';
import 'package:trackify_android/ui/route.dart';
import 'package:trackify_android/ui/router.dart';
import 'package:trackify_android/db/models.dart';
import 'package:trackify_android/ui/widgets/music.dart';
import 'package:trackify_android/ui/widgets/generic_route_filler.dart';

class TrackSearchRoute extends MyRoute {
  Function onSelect;

  TrackSearchRoute({this.onSelect}) : super(path: '/track_search');

  @override
  Widget buildWidget(BuildContext context) {
    return TrackSearchRouteWidget(onSelect: this.onSelect);
  }
}

class TrackSearchRouteWidget extends StatefulWidget {
  Function onSelect;

  TrackSearchRouteWidget({this.onSelect});

  State<TrackSearchRouteWidget> createState() => TrackSearchRouteWidgetState();
}

class TrackSearchRouteWidgetState extends State<TrackSearchRouteWidget> {
  String _query = "";

  @override
  Widget build(BuildContext context) {
    List<Track> tracksThatMatch = [];
    if (_query != "") {
      for (Track track in apiClient.data.tracks.values) {
        if (track.name.toLowerCase().contains(this._query.toLowerCase())) {
          tracksThatMatch.add(track);
          continue;
        }
        bool found = false;
        for (Artist artist in track.artists) {
          if (artist.name.toLowerCase().contains(this._query.toLowerCase())) {
            tracksThatMatch.add(track);
            found = true;
            break;
          }
        }
        if (found) {
          continue;
        }
        if (track.album.name.toLowerCase().contains(this._query.toLowerCase())) {
          tracksThatMatch.add(track);
          continue;
        }
      }
    }
    return GenericRouteFiller(
      title: Text('search for track', style: TextStyle(color: mainBlack, fontSize: 21)),
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
                          this._query = value;
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
                    widget.onSelect(track);
                    Navigator.pop(context);
                  },
                );
              }
            ),
          ),
        ],
      )
    );
  }
}
