import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:trackify_android/ui/route.dart';
import 'package:trackify_android/ui/router.dart';
import 'package:trackify_android/ui/routes/auth/login.dart';
import 'package:trackify_android/ui/routes/auth/register.dart';
import 'package:trackify_android/ui/routes/general/general.dart';
import 'package:trackify_android/static.dart';

class IndexRoute extends MyRoute {
  IndexRoute() : super(path: '/');

  Widget buildWidget(BuildContext context) {
    return FutureBuilder<void>(
      future: () async {
        await apiClient.init();
      }(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(color: Colors.black);
        }
        if (apiClient.hasAccessToken()) {

          /* cant push route while building a widget
          https://stackoverflow.com/questions/47592301/setstate-or-markneedsbuild-called-during-build */
          SchedulerBinding.instance.addPostFrameCallback((_) {
              router.clearRoutes();
              router.pushRoute(GeneralRoute());
          });

          return Container(color: Colors.black);
        } else {
          return Scaffold(
            backgroundColor: mainBlack,
            body: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 30),
                    child: Text('Welcome', style: TextStyle(color: mainRed, fontSize: 40)),
                  ),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(secondaryBlack),
                        foregroundColor: MaterialStateProperty.all<Color>(mainBlack),
                      ),
                      onPressed: () {
                        router.pushRoute(LoginRoute());
                      },
                      child: Text('Login'),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(secondaryBlack),
                        foregroundColor: MaterialStateProperty.all<Color>(mainBlack),
                      ),
                      onPressed: () {
                        router.pushRoute(RegisterRoute());
                      },
                      child: Text('Register'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    );
  }
}
