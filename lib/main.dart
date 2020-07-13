import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trackify_android/api.dart';
import 'package:trackify_android/colors.dart';
import 'package:trackify_android/widgets.dart';

void main() => runApp(TrackifyApp());

class MusicEntryWidget extends StatelessWidget {
  String imageUrl;
  String title;
  String subTitle;

  MusicEntryWidget(this.imageUrl, this.title, this.subTitle);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(21, 5, 20, 5),
      color: dimmerBgColor,
      child: Row(children: <Widget>[
        Container(
          margin: const EdgeInsets.all(4),
          child: Image.network(
            this.imageUrl,
            width: 55,
            height: 55,
            fit: BoxFit.contain,
          )
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              this.subTitle != null
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(this.title),
                    SizedBox(height: 5,),
                    Text(this.subTitle)],
                ) : Text(this.title),
              Text('time goes here')
            ]
          )
        )
      ]),
    );
  }
}

class TrackifyApp extends StatelessWidget {
  APIClient client = APIClient();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: new ThemeData(
        primaryColor: bgColor,
        primaryTextTheme: TextTheme(
          title: TextStyle(
            color: textColor,
          ),
        ),
      ),
      home: FutureBuilder<bool>(
        future: () async { await this.client.init(); return true; } (),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          print(snapshot);
          if (snapshot.hasData) {
            if (this.client.isAuthDone()) {
              return Scaffold(
                backgroundColor: bgColor,
                bottomNavigationBar: BottomNavigationBar(
                  backgroundColor: bgColor,
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home, color: highlightedTextColor ,),
                      title: Text('Home', style: highlightedTextStyle,)
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.history, color: highlightedTextColor ,),
                      title: Text('History', style: highlightedTextStyle,)
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.toc, color: highlightedTextColor ,),
                      title: Text('Leaderboard', style: highlightedTextStyle,)
                    )
                  ],
                ),
                appBar: AppBar(title: Text('Trackify')),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.all(15),
                      child: Text(
                        'top track (past 24 hours)',
                        style: highlightedTextStyle
                      ),
                    ),
                    MusicEntryWidget(
                        'https://i.scdn.co/image/ab67616d00001e02e02e23dc360c5bc2aad59b27',
                        'Neon Moon',
                        'some stupidly great band'),
                    MusicEntryWidget(
                        'https://i.scdn.co/image/ab67616d00001e02e02e23dc360c5bc2aad59b27',
                        'track name goes here',
                        'artist name goes here'),
                  ],
                ),
              );
            } else {
              return Scaffold(
                backgroundColor: bgColor,
                appBar: AppBar(title: Text('Trackify')),
                body: RegisterWidget(),
              );
            }
          } else {
            return Scaffold(
              backgroundColor: bgColor,
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}