import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:trackify_android/config.dart';

String uriEncode(String str) {
  return Uri.encodeFull(str);
}

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

class DbProvider {
  Database db;

  Future<void> open() async {
    if (File((await getExternalStorageDirectory()).path + '/db').existsSync()) {
      await deleteDatabase((await getExternalStorageDirectory()).path + '/db');
    }
    this.db = await openDatabase((await getExternalStorageDirectory()).path + '/db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE albums (
          id TEXT PRIMARY KEY,
          album_name TEXT NOT NULL,
          album_type TEXT NOT NULL,
          release_date TEXT NOT NULL,
          release_date_precision TEXT NOT NULL,
          listened_ms INT NOT NULL
        )
        ''');

        await db.execute('''
        CREATE TABLE tracks (
          track_name TEXT NOT NULL,
          duration_ms INT NOT NULL,
          popularity INT NOT NULL,
          preview_url TEXT,
          track_number INT NOT NULL,
          explicit BOOL NOT NULL,
          album_id TEXT NOT NULL,
          listened_ms INT NOT NULL,
          FOREIGN KEY (album_id) REFERENCES albums (id)
        )
        ''');

        await db.execute('''
        CREATE table artists (
          id TEXT PRIMARY KEY,
          artist_name TEXT NOT NULL,
          listened_ms INT NOT NULL
        )
        ''');

        await db.execute('''
        CREATE TABLE album_artists (
          id TEXT PRIMARY KEY,
          artist_id TEXT NOT NULL,
          album_id TEXT NOT NULL,
          FOREIGN KEY (artist_id) REFERENCES artists (id),
          FOREIGN KEY (album_id) REFERENCES albums (id)
        )
        ''');

        await db.execute('''
        CREATE TABLE track_artists (
          id TEXT PRIMARY KEY,
          artist_id TEXT NOT NULL,
          track_id TEXT NOT NULL,
          FOREIGN KEY (artist_id) REFERENCES artists (id),
          FOREIGN KEY (track_id) REFERENCES tracks (id)
        )
        ''');

        await db.execute('''
        CREATE TABLE plays (
          id TEXT PRIMARY KEY,
          time_started INT NOT NULL,
          time_ended INT NOT NULL,
          track_id TEXT NOT NULL,
          listened_ms INT NOT NULL,
          FOREIGN KEY (track_id) REFERENCES tracks (id)
        )
        ''');
      },
    );
  }

  Future<void> addTrack(Track track) {
    //this.db.insert(table, values)
  }

  Future<void> addPlay(Play play) {
    this.addTrack(play.track);
  }

  Future<void> addPlays(List<Play> plays) {
    for (Play play in plays) {
      this.addPlay(play);
    }
  }
}

class APIClient {
  FlutterSecureStorage secureStorage;
  String accessToken, refreshToken;
  int accessTokenExpiryTime;
  DbProvider dbProvider;

  APIClient() {
    this.secureStorage = new FlutterSecureStorage();
  }

  Future<void> init() async {
    this.dbProvider = DbProvider();
    await this.dbProvider.open();
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

  Future<List<Play>> fetchHistory(int hrsLimit) async {
    http.Response r = await http.get(BACKEND + '/api/history?hrs_limit=' + hrsLimit.toString(), headers: {
      'Authorization': 'Bearer ${this.accessToken}'
    });
    List<Play> plays = [];
    List<dynamic> playsJson = json.decode(r.body);
    for (dynamic playJson in playsJson) {
      plays.add(Play.fromJson(playJson));
    }
    this.dbProvider.addPlays(plays);
    return plays;
  }

  Future<Map<int, List<Track>>> fetchTopTracks(List<int> hrs) async {
    String hrsStr = "";
    for (int hr in hrs) {
      hrsStr += hr.toString() + ",";
    }
    hrsStr = hrsStr.substring(0, hrsStr.length - 1); // get rid of last comma
    http.Response r = await http.get(BACKEND + '/api/top_tracks?hrs=' + uriEncode(hrsStr), headers: {
      'Authorization': 'Bearer ${this.accessToken}'
    });
    Map<int, List<Track>> tracks = {};
    Map<String, dynamic> tracksJson = json.decode(r.body);;
    for (int i = 0; i < hrs.length; ++i) {
      for (dynamic trackJson in tracksJson[hrs[i].toString()]) {
        if (tracks.containsKey(hrs[i])) {
          tracks[hrs[i]].add(Track.fromJson(trackJson));
        } else {
          tracks[hrs[i]] = [Track.fromJson(trackJson)];
        }
      }
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
    print(r.body);
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
