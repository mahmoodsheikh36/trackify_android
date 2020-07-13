import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

String validatePasswordInput(String password) {
  if (password.isEmpty)
    return 'password cant be empty';
  if (password.length > 93)
    return 'password too long';
  return null;
}

String validateUsernameInput(String username) {
  if (username.isEmpty)
    return 'username cant be empty';
  if (username.length > 29) {
    return 'username too long';
  }
  return null;
}

class Track {
  String id;
  String name;
  List<Artist> artists;
  Album album;
  Track(this.id, this.name, this.artists, this.album);
  static Track fromJson(Map<String, dynamic> jsonMap) {
    return Track(jsonMap['id'], jsonMap['name'], null, null);
  }
}

class Artist {
  String id;
  String name;
  Artist(this.id, this.name);
  static Artist fromJson(Map<String, dynamic> jsonMap) {
    return Artist(jsonMap['id'], jsonMap['name']);
  }
}

class Album {
  String id;
  String name;
  List<Artist> artists;
  Album(this.id, this.name, this.artists);
  static Album fromJson(Map<String, dynamic> jsonMap) {
    return Album(jsonMap['id'], jsonMap['name'], null);
  }
}

class Play {
  String id;
  Track track;
  DateTime date;
  Play(this.id, this.track, this.date);
  static Play fromJson(Map<String, dynamic> jsonMap) {
    return Play(jsonMap['id'], Track.fromJson(jsonMap['track']), jsonMap['date']);
  }
}

class APIClient {
  FlutterSecureStorage secureStorage;
  String accessToken, refreshToken;
  int accessTokenExpiryTime;
  APIClient() {
    this.secureStorage = new FlutterSecureStorage();
  }

  Future<void> init() async {
    Map<String, String> accessValues = await secureStorage.readAll();
    String accessToken = accessValues['access_token'];
    if (accessToken != null) {
      this.accessToken = accessToken;
      this.refreshToken = accessValues['refresh_token'];
      this.accessTokenExpiryTime = int.parse(accessValues['expiry_time']);
    }
  }

  void fetchNewAccessTokenIfNeeded() {
    if (this.accessTokenExpiryTime < DateTime.now().millisecondsSinceEpoch) {
      this.fetchAccessToken();
    } else if (this.refreshToken == null) {
    }
  }

  Future<List<Play>> fetchHistory() async {
    http.Response r = await http.get('https://trackifyapp.net/api/history', headers: {
      'Authorization': 'Bearer $this.access_token'
    });
    List<Play> plays = [];
    List<dynamic> playsJson = json.decode(r.body);
    for (dynamic playJson in playsJson) {
      plays.add(Play.fromJson(playJson));
    }
    return plays;
  }

  void fetchAccessToken() async {
    /* fetch it here */
    this.accessTokenExpiryTime =
      new DateTime.now().millisecondsSinceEpoch + 30 * 60 * 1000;
  }

  Future<bool> authenticate(String username, String password) async {
    return await this.fetchRefreshToken(username, password);
  }

  Future<bool> fetchRefreshToken(String username, String password) async {
    http.Response r = await http.post("https://trackifyapp.net/api/login", body: {
      'username': username,
      'password': password
    });
    Map<String, dynamic> rJson =  json.decode(r.body)['refresh_token'];
    if (!rJson.containsKey('refresh_token')) {
      return false;
    }
    String accessToken = rJson['access_token'];
    String refreshToken = rJson['refresh_token'];
    int expiryTime = DateTime.now().millisecondsSinceEpoch + 30 * 60 * 1000;
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.accessTokenExpiryTime = expiryTime;
    return true;
  }

  bool isAuthDone() {
    return this.accessToken != null;
  }
}