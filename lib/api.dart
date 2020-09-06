import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const String BACKEND = 'http://localhost:5000';

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

String validateEmailInput(String email) {
  bool valid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  if (!valid)
    return 'email not valid';
  return null;
}

class Track {
  String id;
  String name;
  Artist artist;
  Album album;
  int msListened;
  Track(this.id, this.name, this.artist, this.album, {this.msListened = 0});
  static Track fromJson(Map<String, dynamic> jsonMap) {
    final track = Track(jsonMap['id'].toString(), jsonMap['name'].toString(), Artist.fromJson(jsonMap['artist']),
                        Album.fromJson(jsonMap['album']));
    if (jsonMap.containsKey('listened_ms'))
      track.msListened = jsonMap['listened_ms'];
    return track;
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
  String imageUrl;
  Album(this.id, this.name, this.artists, this.imageUrl);
  static Album fromJson(Map<String, dynamic> jsonMap) {
    return Album(jsonMap['id'].toString(), jsonMap['name'].toString(), null, jsonMap['cover'].toString());
  }
}

class Play {
  String id;
  Track track;
  DateTime playTime;
  Play(this.id, this.track, this.playTime);
  static Play fromJson(Map<String, dynamic> jsonMap) {
    return Play(jsonMap['id'], Track.fromJson(jsonMap['track']), DateTime.parse(jsonMap['play_time']));
  }
}

class User {
  String username;
  int msListened;
  User(this.username, this.msListened);
  static User fromJson(Map<String, dynamic> jsonMap) {
    return User(jsonMap['username'], jsonMap['listened_ms']);
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
    print('done init');
  }

  void fetchNewAccessTokenIfNeeded() {
    if (this.accessTokenExpiryTime < DateTime.now().millisecondsSinceEpoch) {
      this.fetchAccessToken();
    } else if (this.refreshToken == null) {
    }
  }

  Future<List<Play>> fetchHistory() async {
    http.Response r = await http.get(BACKEND + '/api/history', headers: {
      'Authorization': 'Bearer ${this.accessToken}'
    });
    List<Play> plays = [];
    List<dynamic> playsJson = json.decode(r.body);
    for (dynamic playJson in playsJson) {
      plays.add(Play.fromJson(playJson));
    }
    return plays;
  }

  Future<List<Track>> fetchTopTracks(int hrsLimit) async {
    http.Response r = await http.get(BACKEND + '/api/top_tracks?hrs_limit=' + hrsLimit.toString(), headers: {
      'Authorization': 'Bearer ${this.accessToken}'
    });
    List<Track> tracks = [];
    List<dynamic> tracksJson = json.decode(r.body);
    for (dynamic trackJson in tracksJson) {
      tracks.add(Track.fromJson(trackJson));
    }
    return tracks;
  }

  Future<List<User>> fetchTopUsers(int hrsLimit) async {
    http.Response r = await http.get(BACKEND + '/api/top_users?hrs_limit=' + hrsLimit.toString(), headers: {
      'Authorization': 'Bearer ${this.accessToken}'
    });
    List<User> users = [];
    List<dynamic> usersJson = json.decode(r.body);
    for (dynamic userJson in usersJson) {
      users.add(User.fromJson(userJson));
    }
    return users;
  }

  void fetchAccessToken() async {
    /* fetch it here */
    this.accessTokenExpiryTime =
      new DateTime.now().millisecondsSinceEpoch + 30 * 60 * 1000; // after 30 minutes
  }

  Future<bool> authenticate(String username, String password) async {
    return await this.fetchRefreshToken(username, password);
  }

  Future<bool> fetchRefreshToken(String username, String password) async {
    http.Response r = await http.post(BACKEND + "/api/login", body: {
      'username': username,
      'password': password
    });
    if (r.statusCode != 200)
      return false;
    Map<String, dynamic> rJson = json.decode(r.body);
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

  /* TODO: finish this */
  Future<bool> register(String username, String password, String email) async {
    // http.Response r = await http.post(BACKEND + "/api/login", body: {
    //   'username': username,
    //   'password': password
    // });
    // if (r.statusCode != 202)
    //   return false;
    // Map<String, dynamic> rJson = json.decode(r.body)[''];
  }
}