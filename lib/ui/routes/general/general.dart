import 'package:flutter/material.dart';

import 'package:trackify_android/ui/route.dart';
import 'package:trackify_android/static.dart';
import 'package:trackify_android/api/api.dart';
import 'package:trackify_android/ui/routes/general/home.dart';
import 'package:trackify_android/ui/routes/general/history.dart';
import 'package:trackify_android/ui/routes/general/leaderboard.dart';
import 'package:trackify_android/ui/routes/general/library.dart';

class GeneralRoute extends MyRoute {
  GeneralRoute() : super(path: '/general');

  Widget buildWidget(BuildContext context) {
    return GeneralRouteWidget();
  }
}

class GeneralRouteWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => GeneralRouteWidgetState();
}

class GeneralRouteWidgetState extends State<GeneralRouteWidget> {
  int _bottomNavigationBarIndex = 0;
  PageController _pageController;
  final _libraryWidgetKey = GlobalKey<LibraryWidgetState>();
  DateTime firstPlayDateTime;
  Future<void> _future;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _future = () async {
      await apiClient.fetchNewData();
      await apiClient.loadData(DateTimeHelper.beginningOfMonth(), DateTime.now());
      this.firstPlayDateTime = await apiClient.getFirstPlayDateTime();
    }();
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
    return FutureBuilder<void>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.hasError) {
          print('eror');
          print(snapshot.error);
        }
        if (!apiClient.hasData()) {
          return Center(child: CircularProgressIndicator());
        } else {
          return SafeArea(
            child: Scaffold(
              floatingActionButton: this._bottomNavigationBarIndex == 3 ? FloatingActionButton(
                backgroundColor: mainRed,
                child: Icon(Icons.add, color: mainBlack),
                onPressed: () {
                  (_libraryWidgetKey.currentState as LibraryWidgetState).beginAddCollage(_libraryWidgetKey.currentContext);
                },
              ) : null,
              //backgroundColor: mainBlack,
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: mainRed, width: 2)),
                ),
                child: BottomNavigationBar(
                  selectedItemColor: mainRed,
                  unselectedItemColor: secondaryBlack,
                  backgroundColor: mainBlack,
                  type: BottomNavigationBarType.fixed,
                  items: [
                    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
                    BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
                    BottomNavigationBarItem(icon: Icon(Icons.library_music_outlined), label: 'Library'),
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
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _bottomNavigationBarIndex = index);
                        },
                        children: <Widget>[
                          HomeWidget(),
                          HistoryWidget(),
                          LeaderboardWidget(),
                          LibraryWidget(_libraryWidgetKey),
                        ],
                      )
                    )
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
