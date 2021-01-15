import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
  List<Artist> artists;
  Album album;
  List<Play> plays;
  Track(this.id, this.name, this.artists, this.album, this.plays);

  static Track fromMap(Map<String, dynamic> map) {
    Track track = Track(map['id'], map['name'], [], Album.fromMap(map['album']), []);
    for (Map<String, dynamic> artistJson in map['artists']) {
      track.artists.add(Artist.fromMap(artistJson));
    }
    return track;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'name': this.name,
      'album_id': this.album.id,
    };
  }

  int msPlayed({int fromTime=-1, int toTime=-1}) {
    int total = 0;
    for (Play play in this.plays) {
      total += play.msPlayed(fromTime: fromTime, toTime: toTime);
    }
    return total;
  }
}

class Artist {
  String id;
  String name;
  Artist(this.id, this.name);

  static Artist fromMap(Map<String, dynamic> map) {
    return Artist(map['id'], map['name']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'name': this.name,
    };
  }
}

class Album {
  String id;
  String name;
  List<Artist> artists;
  List<AlbumCover> covers;
  Album(this.id, this.name, this.artists, this.covers);

  static Album fromMap(Map<String, dynamic> map) {
    Album album = Album(map['id'], map['name'], [], []);
    for (Map<String, dynamic> albumCoverMap in map['covers']) {
      album.covers.add(AlbumCover.fromMap(albumCoverMap));
    }
    for (Map<String, dynamic> artistMap in map['artists']) {
      album.artists.add(Artist.fromMap(artistMap));
    }
    return album;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'album_name': this.name,
    };
  }
}

class AlbumCover {
  String url;
  int width;
  int height;
  AlbumCover(this.url, this.width, this.height);

  static AlbumCover fromMap(Map<String, dynamic> map) {
    return AlbumCover(map['url'], map['width'], map['height']);
  }

  Map<String, dynamic> toMap() {
    return {
      'url': this.url,
      'width': this.width,
      'height': this.height,
    };
  }
}

class Play {
  String id;
  Track track;
  int timeStarted;
  int timeEnded;
  List<Pause> pauses;
  List<Resume> resumes;

  Play(this.id, this.track, this.timeStarted, this.timeEnded, this.pauses, this.resumes);

  DateTime startDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(this.timeStarted);
  }

  static Play fromMap(Map<String, dynamic> map) {
    Play play = Play(map['id'], Track.fromMap(map['track']), map['time_started'],
                     map['time_ended'], [], []);
    for (Map<String, dynamic> pauseMap in map['pauses']) {
      play.pauses.add(Pause.fromMap(pauseMap));
    }
    for (Map<String, dynamic> resumeMap in map['resumes']) {
      play.resumes.add(Resume.fromMap(resumeMap));
    }
    return play;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'time_started': this.timeStarted,
      'time_ended': this.timeEnded,
      'track_id': track.id,
    };
  }

  int msPlayed({int fromTime=-1, int toTime=-1}) {
    if (fromTime == -1) {
      fromTime = this.timeStarted;
    } else if (fromTime > this.timeEnded) {
      return 0;
    }
    if (toTime == -1) {
      toTime = this.timeEnded;
    } else if (toTime < this.timeStarted) {
      return 0;
    }
    if (fromTime < this.timeStarted) {
      fromTime = this.timeStarted;
    }
    if (toTime > this.timeEnded) {
      toTime = this.timeEnded;
    }
    int milliseconds = toTime - fromTime;
    for (int i = 0; i < this.resumes.length; ++i) {
      Pause pause = this.pauses[i];
      Resume resume = this.resumes[i];
      int timePaused = pause.timeAdded;
      int timeResumed = resume.timeAdded;
      if (timePaused > toTime) {
        continue;
      }
      if (timeResumed < fromTime) {
        continue;
      }
      if (timePaused < fromTime) {
        timePaused = fromTime;
      }
      if (timeResumed > toTime) {
        timeResumed = toTime;
      }
      milliseconds -= timeResumed - timePaused;
    }
    if (this.pauses.length > this.resumes.length) {
      int timePaused = this.pauses[this.pauses.length - 1].timeAdded;
      if (timePaused < toTime) {
        if (timePaused < fromTime) {
          timePaused = fromTime;
        }
        milliseconds -= toTime - timePaused;
      }
    }
    return milliseconds;
  }

  Duration durationPlayed({int fromTime=-1, int toTime=-1}) {
    return Duration(milliseconds: this.msPlayed(fromTime: fromTime, toTime: toTime));
  }
}

class Pause {
  int timeAdded;
  Pause(this.timeAdded);

  static Pause fromMap(Map<String, dynamic> map) {
    return Pause(map['time_added']);
  }

  Map<String, dynamic> toMap(String playId) {
    return {
      'time_added': this.timeAdded,
      'play_id': playId
    };
  }
}

class Resume {
  int timeAdded;
  Resume(this.timeAdded);

  static Resume fromMap(Map<String, dynamic> map) {
    return Resume(map['time_added']);
  }

  Map<String, dynamic> toMap(String playId) {
    return {
      'time_added': this.timeAdded,
      'play_id': playId,
    };
  }
}

class User {
  String username;
  Duration playDuration;
  Map<Track, Duration> topTracks;
  User(this.username, this.playDuration, this.topTracks);
  static User fromMap(Map<String, dynamic> map) {
    Map<Track, Duration> topTracks = {};
    for (Map<String, dynamic> trackMap in map['top_tracks']) {
      Track track = Track.fromMap(trackMap);
      topTracks[track] = Duration(milliseconds: trackMap['listened_ms']);
    }
    return User(map['username'], Duration(milliseconds: map['listened_ms']), topTracks);
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
          album_name TEXT NOT NULL
        )
        ''');

        await db.execute('''
        CREATE TABLE tracks (
          track_name TEXT NOT NULL,
          album_id TEXT NOT NULL,
          FOREIGN KEY (album_id) REFERENCES albums (id)
        )
        ''');

        await db.execute('''
        CREATE table artists (
          id TEXT PRIMARY KEY,
          artist_name TEXT NOT NULL
        )
        ''');

        await db.execute('''
        CREATE TABLE album_artists (
          artist_id TEXT NOT NULL,
          album_id TEXT NOT NULL,
          FOREIGN KEY (artist_id) REFERENCES artists (id),
          FOREIGN KEY (album_id) REFERENCES albums (id)
        )
        ''');

        await db.execute('''
        CREATE TABLE track_artists (
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

        await db.execute('''
        CREATE TABLE pauses (
          id TEXT PRIMARY KEY,
          time_added INT NOT NULL,
          play_id TEXT NOT NULL,
          FOREIGN KEY (play_id) REFERENCES plays (id)
        )
        ''');

        await db.execute('''
        CREATE TABLE resumes (
          id TEXT PRIMARY KEY,
          time_added INT NOT NULL,
          play_id TEXT NOT NULL,
          FOREIGN KEY (play_id) REFERENCES plays (id)
        )
        ''');
      },
    );
  }

  Future<void> addData(APIData data) async {
    var batch = db.batch();
    for (Play play in data.plays.values) {
      batch.insert('plays', play.toMap());
      for (Pause pause in play.pauses) {
        batch.insert('pauses', pause.toMap(play.id));
      }
      for (Resume resume in play.resumes) {
        batch.insert('resumes', resume.toMap(play.id));
      }
    }
    for (Album album in data.albums.values) {
      batch.insert('albums', album.toMap());
      for (Artist artist in album.artists) {
        batch.insert('album_artists', {
          'album_id': album.id,
          'artist_id': artist.id,
        });
      }
    }
    for (Track track in data.tracks.values) {
      batch.insert('tracks', track.toMap());
      for (Artist artist in track.artists) {
        batch.insert('track_artists', {
          'track_id': track.id,
          'artist_id': artist.id,
        });
      }
    }
    for (Artist artist in data.artists.values) {
      batch.insert('artists', artist.toMap());
    }
    await batch.commit();
  }

  Future<APIData> getData() {
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

  Future<void> saveAuthData() async {
    print(this.accessToken);
    await this.secureStorage.write(key: 'refresh_token', value: this.refreshToken);
    await this.secureStorage.write(key: 'access_token', value: this.accessToken);
    await this.secureStorage.write(key: 'access_token_expiry_time', value: this.accessTokenExpiryTime.toString());
    print(this.refreshToken);
  }

  Future<void> init() async {
    this.dbProvider = DbProvider();
    await this.dbProvider.open();
    Map<String, String> accessValues = await this.secureStorage.readAll();
    print(accessValues);
    String accessToken = accessValues['access_token'];
    if (accessToken != null) {
      this.accessToken = accessToken;
      this.refreshToken = accessValues['refresh_token'];
      this.accessTokenExpiryTime = int.parse(accessValues['access_token_expiry_time']);
    }
  }

  Future<void> fetchAccessTokenIfExpired() async {
    if (this.accessTokenExpiryTime < DateTime.now().millisecondsSinceEpoch) {
      this.fetchAccessToken();
    }
  }

  Future<List<User>> fetchTopUsers(int fromTime, int toTime) async {
    await this.fetchAccessTokenIfExpired();
    http.Response r = await http.get(BACKEND + '/api/top_users?from_time=' + fromTime.toString() + '&to_time=' + toTime.toString(),
      headers: {
        'Authorization': 'Bearer ${this.accessToken}'
      }
    );
    List<User> users = [];
    List<dynamic> usersJson = json.decode(r.body);
    for (dynamic userJson in usersJson) {
      users.add(User.fromMap(userJson));
    }
    return users;
  }

  Future<void> fetchAccessToken() async {
    http.Response r = await http.post(BACKEND + "/api/refresh", body: {
        'refresh_token': this.refreshToken,
      }, headers: {
        'Authorization': 'Bearer ${this.refreshToken}',
      }
    );
    print(r.body);
    if (r.statusCode != 200)
      return false;
    Map<String, dynamic> rJson = json.decode(r.body);
    this.accessToken = rJson['access_token'];
    this.accessTokenExpiryTime =
      new DateTime.now().millisecondsSinceEpoch + 30 * 60 * 1000; // after 30 minutes
    this.saveAuthData();
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
    await this.saveAuthData();
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

  Future<APIData> fetchThisMonthData() async {
    final now = DateTime.now();
    int beginningOfMonth = new DateTime(now.year, now.month).millisecondsSinceEpoch;
    return this.fetchData(beginningOfMonth, now.millisecondsSinceEpoch);
  }

  Future<APIData> fetchData(int fromTime, int toTime) async {
    await this.fetchAccessTokenIfExpired();
    http.Response r = await http.get(BACKEND + '/api/data?from_time=' + fromTime.toString() + "&to_time=" + toTime.toString(),
      headers: {
        'Authorization': 'Bearer ${this.accessToken}'
      }
    );

    Map<String, Play> plays = {};
    Map<String, Artist> artists = {};
    Map<String, Track> tracks = {};
    Map<String, Album> albums = {};

    List<dynamic> playsJson = json.decode(r.body);
    for (dynamic playJson in playsJson) {
      Play play = Play.fromMap(playJson);
      plays[play.id] = play;
      albums[play.track.album.id] = play.track.album;
      if (!tracks.containsKey(play.track.id)) {
        tracks[play.track.id] = play.track;
      }
      tracks[play.track.id].plays.add(play);
      for (Artist artist in play.track.artists) {
        artists[artist.id] = artist;
      }
      for (Artist artist in play.track.album.artists) {
        artists[artist.id] = artist;
      }
    }
    APIData data = APIData(artists, albums, tracks, plays);
    int lastMidnight = DateTimeHelper.lastMidnight().millisecondsSinceEpoch;
    //await this.dbProvider.addData(data);
    return data;
  }
}

class APIData {
  Map<String, Artist> artists;
  Map<String, Album> albums;
  Map<String, Track> tracks;
  Map<String, Play> plays;

  APIData(this.artists, this.albums, this.tracks, this.plays);

  Map<Track, Duration> topTracksToday({int limit=-1}) {
    int lastMidnight = DateTimeHelper.lastMidnight().millisecondsSinceEpoch;
    return this.topTracks(lastMidnight, DateTime.now().millisecondsSinceEpoch, limit: limit);
  }

  Map<Track, Duration> topTracksThisMonth({int limit=-1}) {
    int beginningOfMonth = DateTimeHelper.beginningOfMonth().millisecondsSinceEpoch;
    return this.topTracks(beginningOfMonth, DateTime.now().millisecondsSinceEpoch, limit: limit);
  }

  Map<Track, Duration> topTracksThisWeek({int limit=-1}) {
    int beginningOfWeek = DateTimeHelper.beginningOfWeek().millisecondsSinceEpoch;
    return this.topTracks(beginningOfWeek, DateTime.now().millisecondsSinceEpoch, limit: limit);
  }

  Map<Track, Duration> topTracks(int fromTime, int toTime, {int limit=-1}) {
    if (limit == -1) limit = this.tracks.keys.length;
    Map<Track, int> tracksMsPlayed = {};
    for (Track track in this.tracks.values) {
      for (Play play in track.plays) {
        int msPlayed = play.msPlayed(fromTime: fromTime, toTime: toTime);
        if (msPlayed > 0) {
          if (tracksMsPlayed.containsKey(track)) {
            tracksMsPlayed[track] += play.msPlayed(fromTime: fromTime, toTime: toTime);
          } else {
            tracksMsPlayed[track] = play.msPlayed(fromTime: fromTime, toTime: toTime);
          }
        }
      }
    }
    List<Track> topTracks = [];
    for (Track track in this.tracks.values) {
      if (tracksMsPlayed.containsKey(track)) {
        int msPlayed = tracksMsPlayed[track];
        for (int i = 0; i < limit; ++i) {
          if (i < topTracks.length) {
            Track otherTrack = topTracks[i];
            if (msPlayed > tracksMsPlayed[otherTrack]) {
              topTracks.insert(i, track);
              if (topTracks.length > limit) {
                topTracks.removeAt(limit);
              }
              break;
            }
          } else {
            topTracks.add(track);
            break;
          }
        }
      }
    }
    Map<Track, Duration> topTracksDurationMap = {};
    for (Track track in topTracks) {
      topTracksDurationMap[track] = Duration(milliseconds: tracksMsPlayed[track]);
    }
    if (topTracks.length == 0)
      return null;
    return topTracksDurationMap;
  }

  /* TODO: implement a better algorithm */
  List<Track> getRandomTracks(int count) {
    List<Track> randomTracks = [];
    List<Track> allTracks = [];
    Random rng = Random();
    for (Track track in this.tracks.values) {
      allTracks.add(track);
    }
    if (allTracks.length < count) {
      return null;
    }
    for (int i = 0; i < count; ++i) {
      int idx = rng.nextInt(allTracks.length);
      randomTracks.add(allTracks[idx]);
      allTracks.removeAt(idx);
    }
    return randomTracks;
  }

  List<Play> sortedPlays() {
    List<Play> sortedPlays = [];
    for (Play play in this.plays.values) {
      bool inserted = false;
      for (int i = 0; i < sortedPlays.length; ++i) {
        if (sortedPlays[i].timeStarted < play.timeStarted) {
          sortedPlays.insert(i, play);
          inserted = true;
          break;
        }
      }
      if (!inserted) {
        sortedPlays.add(play);
      }
    }
    return sortedPlays;
  }
}

class DateTimeHelper {
  static DateTime lastMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  static DateTime beginningOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }
  static DateTime beginningOfWeek() {
    final now = DateTime.now();
    return now.subtract(new Duration(days: now.weekday));
  }
}
