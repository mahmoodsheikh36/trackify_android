import 'package:flutter/material.dart';

import 'package:trackify_android/static.dart';
import 'package:trackify_android/db/models.dart';

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
