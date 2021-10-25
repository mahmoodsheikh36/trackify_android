import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:trackify_android/ui/route.dart';
import 'package:trackify_android/ui/routes/index.dart';
import 'package:trackify_android/static.dart';

class MyRouter {
  Map<String, MyRoute> routes = {};
  List<MyRoute> currentRoutes = [];
  Function onPushRoute = (MyRoute r) {};
  void clearRoutes() {
    this.routes = {};
    this.currentRoutes = [];
  }
  void pushRoute(MyRoute r) {
    onPushRoute(r);
    // implemented later in routerDelegate
  }
}

MyRouter router = MyRouter();

class TrackifyApp extends StatefulWidget {
  TrackifyApp() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        systemNavigationBarColor: mainBlack, // navigation bar color
        statusBarColor: mainRed, // status bar color
    ));
    router.currentRoutes.add(IndexRoute());
  }

  @override
  State<StatefulWidget> createState() => TrackifyAppState();
}

class TrackifyAppState extends State<TrackifyApp> {
  MyRouterDelegate _routerDelegate = MyRouterDelegate();
  MyRouteInformationParser _routeInformationParser = MyRouteInformationParser();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'trackify app',
      routerDelegate: _routerDelegate,
      routeInformationParser: _routeInformationParser,
    );
  }
}

class MyRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  final GlobalKey<NavigatorState> navigatorKey;

  MyRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>() {
    router.onPushRoute = (MyRoute r) {
      router.currentRoutes.add(r);
      notifyListeners();
    };
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        for (int i = 0; i < router.currentRoutes.length; ++i)
          router.currentRoutes[i]
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        router.currentRoutes.removeAt(router.currentRoutes.length - 1);
        notifyListeners();
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(String path) async {
    print('should change path to ' + path);
  }

  String get currentConfiguration {
    return router.currentRoutes[router.currentRoutes.length - 1].path;
  }
}

class MyRouteInformationParser extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(
      RouteInformation routeInformation) async {
    return routeInformation.location;
    //final uri = Uri.parse(routeInformation.location);
    //if (uri.pathSegments.length == 0) {
      //return '/';
    //}
  }

  @override
  RouteInformation restoreRouteInformation(String path) {
    return RouteInformation(location: path);
    //if (path.isUnknown) {
    //  return RouteInformation(location: '/404');
    //}
    //if (path.isHomePage) {
    //  return RouteInformation(location: '/');
    //}
    //if (path.isDetailsPage) {
    //  return RouteInformation(location: '/book/${path.id}');
    //}
    //return null;
  }
}
