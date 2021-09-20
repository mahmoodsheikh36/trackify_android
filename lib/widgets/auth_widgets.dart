import 'package:flutter/material.dart';

import 'package:trackify_android/api/api.dart';
import 'package:trackify_android/config.dart';
import 'package:trackify_android/api/auth.dart';
import 'package:trackify_android/widgets/music_widgets.dart';
import 'package:trackify_android/widgets/widgets.dart';

class AfterAuthWidget extends StatefulWidget {
  final APIClient apiClient;

  AfterAuthWidget(this.apiClient);
  
  @override
  State<StatefulWidget> createState() => AfterAuthWidgetState(this.apiClient);
}

class AfterAuthWidgetState extends State<AfterAuthWidget> {
  int _bottomNavigationBarIndex = 0;
  PageController _pageController;
  APIClient apiClient;
  final _libraryWidgetKey = GlobalKey<LibraryWidgetState>();
  DateTime firstPlayDateTime;

  AfterAuthWidgetState(this.apiClient);

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
      future: () async {
        if (!this.apiClient.hasData()) {
          await this.apiClient.fetchNewData();
          await this.apiClient.loadData(DateTimeHelper.beginningOfMonth(), DateTime.now());
          this.firstPlayDateTime = await this.apiClient.getFirstPlayDateTime();
        }
      }(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error);
        }
        if (!this.apiClient.hasData()) {
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
                          HomeWidget(this.apiClient),
                          HistoryWidget(this.apiClient, this.firstPlayDateTime),
                          LeaderboardWidget(this.apiClient),
                          LibraryWidget(this.apiClient, _libraryWidgetKey),
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
    return Scaffold(body: registerNotLogin ? RegisterWidget(widget.apiClient, this) :
      LoginWidget(widget.apiClient, this, () { widget.rootWidgetState.setState(() { }); }));
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
