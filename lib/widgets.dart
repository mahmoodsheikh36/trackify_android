import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:trackify_android/config.dart';
import 'package:trackify_android/api.dart';

var horizontalExampleWidget = HorizontalMusicEntryWidget(
  'https://i.scdn.co/image/ab67616d00004851572f05af2c4a51eaf9117d76',
  'track title',
  'artist name',
  null
);

var verticalExampleWidget = VerticalMusicEntryWidget(
  'https://i.scdn.co/image/ab67616d00004851572f05af2c4a51eaf9117d76',
  'track title',
  'artist name',
  '3 hrs, 18 mins, 50 secs'
);

class VerticalMusicEntryWidget extends StatelessWidget {
  String imageUrl;
  String title;
  String subTitle;
  String info;

  VerticalMusicEntryWidget(this.imageUrl, this.title, this.subTitle, this.info);

  static VerticalMusicEntryWidget fromTrack(Track track) {
    return VerticalMusicEntryWidget(track.album.imageUrl, track.name, track.artist.name,
        (track.msListened / 1000 / 60 / 60).toInt().toString() + ' hrs ' +
        ((track.msListened / 1000 / 60) % 60).toInt().toString() + ' mins ' +
        ((track.msListened / 1000) % 60).toInt().toString() + ' secs'
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(child: Container(
      margin: const EdgeInsets.all(4),
      child: Column(children: <Widget>[
        Container(
          child: Image.network(
            this.imageUrl,
            width: 130,
            height: 130,
            fit: BoxFit.contain,
          )
        ),
        SizedBox(height: 5),
        Expanded(
          child: Column(
            children: [
              this.subTitle != null
                ? Flexible(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(this.title, overflow: TextOverflow.ellipsis, style: TextStyle(color: mainRed)),
                      Text(this.subTitle, overflow: TextOverflow.ellipsis, style: TextStyle(color: secondaryBlack)),
                      if (this.info != null) Text(this.info, style: TextStyle(color: secondaryBlack, fontSize: 12)),
                  ])) : Text(this.title),
            ]
          )
        )
      ], crossAxisAlignment: CrossAxisAlignment.start,),
      width: 140,
    ), borderRadius: BorderRadius.circular(7),);
  }
}

class HorizontalMusicEntryWidget extends StatelessWidget {
  String imageUrl;
  String title;
  String subTitle;
  Widget info;

  HorizontalMusicEntryWidget(this.imageUrl, this.title, this.subTitle, this.info);

  static HorizontalMusicEntryWidget fromTrack(Track track) {
    return HorizontalMusicEntryWidget(track.album.imageUrl, track.name, track.artist.name, Column(
      children: [
        Text((track.msListened / 1000 / 60 / 60).toInt().toString() + ' hrs'),
        Text(((track.msListened / 1000 / 60) % 60).toInt().toString() + ' mins'),
        Text(((track.msListened / 1000) % 60).toInt().toString() + ' secs'),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(child: Container(
      color: Color.fromRGBO(17, 17, 17, 0.65),
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(this.title, overflow: TextOverflow.ellipsis, style: TextStyle(color: mainRed)),
                      SizedBox(height: 5,),
                      Text(this.subTitle, overflow: TextOverflow.ellipsis, style: TextStyle(color: secondaryBlack)),
                  ])) : Text(this.title),
              if (this.info != null) this.info,
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
  Future<bool> future;

  Future<bool> init() async {
    await widget.apiClient.init();
    return true;
  }

  @override
  void initState() { 
    super.initState();
    this.future = this.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: new ThemeData(
        primaryColor: mainBlack,
        primaryTextTheme: TextTheme(
          title: TextStyle(
            color: textColor,
          ),
        ),
      ),
      home: FutureBuilder<bool>(
        future: this.future,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            if (widget.apiClient.isAuthDone()) {
              return HomeWidget(widget.apiClient, this);
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

class HomeWidget extends StatefulWidget {
  final APIClient apiClient;
  final RootWidgetState rootWidgetState;

  HomeWidget(this.apiClient, this.rootWidgetState);
  
  @override
  State<StatefulWidget> createState() => HomeWidgetState(this.apiClient);
}

class HomeWidgetState extends State<HomeWidget> {
  int _bottomNavigationBarIndex = 0;
  PageController _pageController;
  Widget _generalWidget;
  Widget _historyWidget;
  Widget _leaderboardWidget;

  HomeWidgetState(APIClient apiClient) {
    _generalWidget = GeneralWidget(apiClient);
    _historyWidget = HistoryWidget(apiClient);
    _leaderboardWidget = LeaderboardWidget(apiClient);
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

  void bottomNavigationBarOnTap(int index) {
    setState(() {
      _pageController.animateToPage(index,
        duration: Duration(milliseconds: 500), curve: Curves.easeOut);
      _bottomNavigationBarIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: mainBlack,
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: mainRed,
          unselectedItemColor: secondaryBlack,
          backgroundColor: mainBlack, items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'General'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
          ],
          onTap: this.bottomNavigationBarOnTap,
          currentIndex: this._bottomNavigationBarIndex,
        ),
        body: SizedBox.expand(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _bottomNavigationBarIndex = index);
            },
            children: <Widget>[
              _generalWidget,
              _historyWidget,
              _leaderboardWidget,
            ],
          ),
        ),
      )
    );
  }
}

class GeneralWidget extends StatelessWidget {
  final APIClient apiClient;

  List<Track> topTracksToday;
  List<Track> topTracksThisWeek;
  List<Track> topTracksThisMonth;

  Future<bool> future;

  GeneralWidget(this.apiClient) {
    this.future = fetchData();
  }

  Future<bool> fetchData() async {
    Map<int, List<Track>> topTracks = await this.apiClient.fetchTopTracks([24, 24 * 7, 24 * 30]);;
    this.topTracksThisMonth = topTracks[24 * 30];
    this.topTracksThisWeek = topTracks[24 * 7];
    this.topTracksToday = topTracks[24];
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: this.future,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              //Column(children: <Widget>[
              //  Container(child: Center(child: Text('your top song today', style: highlightedTextStyle)), height: 40,),
              //  if (this.topTracksToday != null) MusicEntryWidget.fromTrack(this.topTracksToday[0]),
              //]),
              //SizedBox(height: 30),
              //Column(children: <Widget>[
              //  Container(child: Center(child: Text('your top song this week', style: highlightedTextStyle))),
              //  SizedBox(height: 20,),
              //  if (this.topTracksThisWeek != null) MusicEntryWidget.fromTrack(this.topTracksThisWeek[0]),
              //]),
              //SizedBox(height: 30),
              //Column(children: <Widget>[
              //  Container(child: Center(child: Text('your top song this month', style: highlightedTextStyle))),
              //  SizedBox(height: 20,),
              //  if (this.topTracksThisMonth != null) MusicEntryWidget.fromTrack(this.topTracksThisMonth[0]),
              //]),
              Container(
                child: Text('Good day', style: TextStyle(color: mainRed, fontSize: 25)),
                padding: EdgeInsets.all(15),
              ),
              Container(child: Row(
                children: [
                  Expanded(child: horizontalExampleWidget),
                  SizedBox(width: 5),
                  Expanded(child: horizontalExampleWidget),
                ],
              ), padding: EdgeInsets.fromLTRB(10, 0, 10, 5)),
              Container(child: Row(
                children: [
                  Expanded(child: horizontalExampleWidget),
                  SizedBox(width: 5),
                  Expanded(child: horizontalExampleWidget),
                ],
              ), padding: EdgeInsets.fromLTRB(10, 0, 10, 5)),
              if (this.topTracksToday != null) Container(
                child: Text('Top tracks today', style: TextStyle(color: mainRed, fontSize: 25)),
                padding: EdgeInsets.all(15),
              ),
              if (this.topTracksToday != null) Container(child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (Track track in this.topTracksToday) Container(
                    child: VerticalMusicEntryWidget.fromTrack(track),
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 5),
                  ),
                ],
              ), height: 200),
              if (this.topTracksThisWeek != null) Container(
                child: Text('Top tracks this week', style: TextStyle(color: mainRed, fontSize: 25)),
                padding: EdgeInsets.all(15),
              ),
              if (this.topTracksThisWeek != null) Container(child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (Track track in this.topTracksThisWeek) Container(
                    child: VerticalMusicEntryWidget.fromTrack(track),
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 5),
                  ),
                ],
              ), height: 200),
              if (this.topTracksThisMonth != null) Container(
                child: Text('Top tracks this month', style: TextStyle(color: mainRed, fontSize: 25)),
                padding: EdgeInsets.all(15),
              ),
              if (this.topTracksThisMonth != null) Container(child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (Track track in this.topTracksThisMonth) Container(
                    child: VerticalMusicEntryWidget.fromTrack(track),
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 5),
                  ),
                ],
              ), height: 200),
            ],
          ));
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class HistoryWidget extends StatelessWidget {
  final APIClient apiClient;

  HistoryWidget(this.apiClient);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Play>>(
      future: this.apiClient.fetchHistory(24 * 7),
      builder: (BuildContext context, AsyncSnapshot<List<Play>> snapshot) {
        if (snapshot.hasData) {
          return Scrollbar(child: ListView.builder(
            itemCount: snapshot.data.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Container(child: Center(child: Text('History', style: highlightedTextStyle,)), height: 50,);
              } else {
                Play play = snapshot.data[index - 1];
                return HorizontalMusicEntryWidget(play.track.album.imageUrl, play.track.name, play.track.artist.name,
                  Column(children: [
                    Text('${play.playTime.hour}:${play.playTime.minute}:${play.playTime.second}'),
                    Text('${play.playTime.day}/${play.playTime.month}/${play.playTime.year}'),
                  ])
                );
              }
            },
          ));
        } else {
          return Center(child: CircularProgressIndicator());
        }
      }
    );
  }

}

class LeaderboardWidget extends StatelessWidget {
  final APIClient apiClient;

  LeaderboardWidget(this.apiClient);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: this.apiClient.fetchTopUsers(0),
      builder: (BuildContext context, AsyncSnapshot<List<User>> snapshot) {
        if (snapshot.hasData) {
          return Scrollbar(child: ListView.builder(
            itemCount: snapshot.data.length  + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  DropdownButton(
                    value: 'past day',
                    items: <String>['past day', 'past week', 'past month'].map((String value) {
                      return new DropdownMenuItem<String>(
                        value: value,
                        child: new Text(value),
                      );
                    }).toList(),
                    onChanged: null
                  )
                ]);
              } else {
                User user = snapshot.data[index - 1];
                return Container(child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        child: Text(user.username, overflow: TextOverflow.ellipsis, style: highlightedTextStyle,),
                        margin: EdgeInsets.all(5),
                      ),
                    ),
                    Container(child:
                      Column(
                        children: [
                          Text((user.msListened / 1000 / 60 / 60).toInt().toString() + ' hrs', style: textStyle,),
                          Text(((user.msListened / 1000 / 60) % 60).toInt().toString() + ' mins', style: textStyle,),
                          Text(((user.msListened / 1000) % 60).toInt().toString() + ' secs', style: textStyle,),
                        ]
                      ), margin: EdgeInsets.all(5)
                    )
                  ]
                ), color: Colors.black, margin: EdgeInsets.fromLTRB(10, 5, 10, 5), height: 70);
              }
            }
          ));
        } else {
          return Center(child: CircularProgressIndicator());
        }
      }
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
    if (USERNAME != null && PASSWORD != null && kDebugMode) {
      return FutureBuilder(
        future: () async {
          await widget.apiClient.authenticate(USERNAME, PASSWORD);
          if (widget.apiClient.isAuthDone()) {
            widget.rootWidgetState.setState(() { });
          } else {
            throw new Exception("couldnt authenticate with username/password that were set in config.dart");
          }
        }(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          return Center(child: CircularProgressIndicator(backgroundColor: mainRed,));
        }
      );
    }
    return Scaffold(body: registerNotLogin ? RegisterWidget(widget.apiClient, this) :
      LoginWidget(widget.apiClient, this, () { widget.rootWidgetState.setState(() { }); }));
    // if (registerNotLogin)
    //   return RegisterWidget(widget.apiClient, this);
    // return LoginWidget(widget.apiClient, this, () {
      
    // });
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
