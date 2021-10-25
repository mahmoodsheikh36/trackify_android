import 'package:flutter/material.dart';

import 'package:trackify_android/static.dart';
import 'package:trackify_android/db/models.dart';
import 'package:trackify_android/ui/router.dart';
import 'package:trackify_android/ui/widgets/music.dart';
import 'package:trackify_android/ui/widgets/placeholders.dart';
import 'package:trackify_android/ui/routes/music/track_search.dart';
import 'package:trackify_android/ui/routes/music/collage.dart';

class LibraryWidget extends StatefulWidget {
  LibraryWidget(Key key) : super(key: key);

  State<LibraryWidget> createState() => LibraryWidgetState();
}

class LibraryWidgetState extends State<LibraryWidget> {
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
                  await apiClient.addCollage(_controller.text);
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
      itemCount: apiClient.data.collages.keys.length,
      itemBuilder: (BuildContext context, int index) {
        Collage collage = apiClient.data.collages.values.elementAt(index);
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
                router.pushRoute(CollageRoute(collage: collage));
              }
            )
          ),
          padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
        );
      }
    );
  }
}
