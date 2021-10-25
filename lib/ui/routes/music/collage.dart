import 'package:flutter/material.dart';

import 'package:trackify_android/static.dart';
import 'package:trackify_android/ui/route.dart';
import 'package:trackify_android/ui/router.dart';
import 'package:trackify_android/db/models.dart';
import 'package:trackify_android/ui/widgets/generic_route_filler.dart';
import 'package:trackify_android/ui/widgets/music.dart';
import 'package:trackify_android/ui/routes/music/track_search.dart';

enum CollageControlType {
  add_track, remove_track, rename_collage, delete_collage
}

class CollageRoute extends MyRoute {
  Collage collage;
  CollageRoute({this.collage}) : super(path: '/collage');

  @override
  Widget buildWidget(BuildContext context) {
    return CollageRouteWidget(collage: this.collage);
  }
}

class CollageRouteWidget extends StatefulWidget {
  Collage collage;

  CollageRouteWidget({this.collage});

  State<CollageRouteWidget> createState() => CollageRouteWidgetState();
}

class CollageRouteWidgetState extends State<CollageRouteWidget> {
  @override
  Widget build(BuildContext context) {
    int _tracksPerRow = 3;
    return GenericRouteFiller(
      title: Text(widget.collage.name, style: TextStyle(color: mainBlack, fontSize: 21)),
      controls: PopupMenuButton(
        icon: Icon(Icons.more_vert, color: mainBlack),
        color: secondaryBlack,
        onSelected: (CollageControlType controlType) {
          if (controlType == CollageControlType.add_track) {
            router.pushRoute(
              TrackSearchRoute(
                onSelect: (Track track) async {
                  await apiClient.addTrackToCollage(widget.collage, track);
                  //this.libraryWidgetSetState(() {});
                  setState(() {});
                }
              )
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
      child: ListView.builder(
        itemCount: widget.collage.tracks.length % _tracksPerRow > 0 ? widget.collage.tracks.length ~/ _tracksPerRow + 1 : widget.collage.tracks.length ~/ _tracksPerRow,
        itemBuilder: (BuildContext context, int index) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: index * _tracksPerRow + _tracksPerRow < widget.collage.tracks.length ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.start,
            children: [
              for (int i = index * _tracksPerRow; i < index * _tracksPerRow + _tracksPerRow; ++i) Flexible(
                child: InkWell(
                  child: Container(
                    padding: EdgeInsets.all(2),
                    child: i < widget.collage.tracks.length ? VerticalMusicEntryWidget.fromTrack(widget.collage.tracks.elementAt(i)) : Container(width: 500),
                  ),
                  onTap: () {
                    //Navigator.push(
                    //  context,
                    //  MaterialPageRoute(builder: (context) => TrackHistoryWidget(collage.tracks.elementAt(i))),
                    //);
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
