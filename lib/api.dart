import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

import 'package:trackify_android/static.dart';

String randomString(int length) {
  const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();
  return String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
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
      'track_name': this.name,
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
      'artist_name': this.name,
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

  AlbumCover get largeCover {
    AlbumCover largest;
    for (AlbumCover cover in this.covers) {
      if (largest == null || cover.width > largest.width) {
        largest = cover;
      }
    }
    return largest;
  }

  AlbumCover get smallCover {
    AlbumCover smallest;
    for (AlbumCover cover in this.covers) {
      if (smallest == null || cover.width < smallest.width) {
        smallest = cover;
      }
    }
    return smallest;
  }

  AlbumCover get midSizedCover {
    List<int> indicies = [0, 1, 2];
    indicies.remove(this.covers.indexOf(this.smallCover));
    indicies.remove(this.covers.indexOf(this.largeCover));
    return this.covers[indicies[0]];
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
      play.pauses.add(Pause.fromMap(pauseMap, play));
    }
    for (Map<String, dynamic> resumeMap in map['resumes']) {
      play.resumes.add(Resume.fromMap(resumeMap, play));
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
  String id;
  int timeAdded;
  Play play;

  Pause(this.id, this.play, this.timeAdded);

  static Pause fromMap(Map<String, dynamic> map, Play play) {
    return Pause(map['id'], play, map['time_added']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time_added': this.timeAdded,
      'play_id': this.play.id
    };
  }
}

class Resume {
  String id;
  int timeAdded;
  Play play;

  Resume(this.id, this.play, this.timeAdded);

  static Resume fromMap(Map<String, dynamic> map, Play play) {
    return Resume(map['id'], play, map['time_added']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'time_added': this.timeAdded,
      'play_id': this.play.id,
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

class Collage {
  String id;
  String name;
  List<Track> tracks;
  Collage(this.id, this.name, {this.tracks}) {
    if (this.tracks == null) this.tracks = [];
  }
  void addTrack(Track track) {
    this.tracks.add(track);
  }
}

class DbProvider {
  Database db;

  Future<void> open() async {
    if (File((await getExternalStorageDirectory()).path + '/db').existsSync()) {
      //await deleteDatabase((await getExternalStorageDirectory()).path + '/db');
    }
    String path = (await getExternalStorageDirectory()).path + (kDebugMode ? '/debug_db' : '/db');
    this.db = await openDatabase(path,
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
          id TEXT PRIMARY KEY,
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

        await db.execute('''
        CREATE TABLE collages (
          id TEXT PRIMARY KEY,
          remote_id TEXT,
          name TEXT NOT NULL
        )
        ''');

        await db.execute('''
        CREATE TABLE collage_track_adds (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          track_id TEXT NOT NULL,
          collage_id INTEGER NOT NULL,
          FOREIGN KEY (track_id) REFERENCES tracks (id),
          FOREIGN KEY (collage_id) REFERENCES collages (id)
        )
        ''');

        await db.execute('''
        CREATE TABLE collage_track_removes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          track_id TEXT NOT NULL,
          collage_id INTEGER NOT NULL,
          FOREIGN KEY (track_id) REFERENCES tracks (id),
          FOREIGN KEY (collage_id) REFERENCES collages (id)
        )
        ''');

        await db.execute('''
        CREATE TABLE album_images (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          url TEXT NOT NULL,
          width INT NOT NULL,
          height INT NOT NULL,
          album_id TEXT NOT NULL,
          FOREIGN KEY (album_id) REFERENCES albums (id)
        )
        ''');

        await db.execute('''
          CREATE INDEX time_started_index ON plays(time_started);
          CREATE INDEX time_ended_index ON plays(time_ended);
        ''');
      },
    );
  }

  Future<List<String>> getIdsOfTable(String tableName) async {
    List<Map<String, dynamic>> data = await this.db.rawQuery('''
      SELECT id FROM ${tableName}
    ''');
    List<String> ids = [];
    for (Map<String, dynamic> entry in data) {
      ids.add(entry['id']);
    }
    return ids;
  }

  Future<void> addData(APIData data) async {
    var batch = db.batch();
    for (Play play in data.plays.values) {
      await batch.rawInsert('''
        INSERT OR REPLACE INTO
        plays(id, time_started, time_ended, track_id)
        VALUES(?, ?, ?, ?)
        ''', [play.id, play.timeStarted, play.timeEnded, play.track.id]
      );
      for (Pause pause in play.pauses) {
        await batch.rawInsert('''
          INSERT OR REPLACE INTO
          pauses(id, time_added, play_id)
          VALUES(?, ?, ?)
          ''', [pause.id, pause.timeAdded, pause.play.id]
        );
      }
      for (Resume resume in play.resumes) {
        await batch.rawInsert('''
          INSERT OR REPLACE INTO
          resumes(id, time_added, play_id)
          VALUES(?, ?, ?)
          ''', [resume.id, resume.timeAdded, resume.play.id]
        );
      }
    }
    List<String> existingIds = await this.getIdsOfTable('albums');
    for (Album album in data.albums.values) {
      if (existingIds.contains(album.id))
        continue;
      await batch.insert('albums', album.toMap());
      for (Artist artist in album.artists) {
        await batch.insert('album_artists', {
          'album_id': album.id,
          'artist_id': artist.id,
        });
      }
      for (AlbumCover cover in album.covers) {
        await batch.insert('album_images', {
          'album_id': album.id,
          'url': cover.url,
          'width': cover.width,
          'height': cover.height,
        });
      }
    }
    existingIds = await this.getIdsOfTable('tracks');
    for (Track track in data.tracks.values) {
      if (existingIds.contains(track.id))
        continue;
      await batch.insert('tracks', track.toMap());
      for (Artist artist in track.artists) {
        await batch.insert('track_artists', {
          'track_id': track.id,
          'artist_id': artist.id,
        });
      }
    }
    existingIds = await this.getIdsOfTable('artists');
    for (Artist artist in data.artists.values) {
      if (existingIds.contains(artist.id))
        continue;
      await batch.insert('artists', artist.toMap());
    }
    await batch.commit();
  }

  Future<APIData> getData(int fromTime, int toTime) async {
    List<Map<String, dynamic>> data = await this.db.rawQuery('''
      SELECT
      p.id as play_id,
      p.time_started as play_time_started,
      p.time_ended as play_time_ended,
      t.id as track_id,
      t.track_name as track_name,
      a.id as album_id,
      a.album_name as album_name,
      ar.id as artist_id,
      ar.artist_name as artist_name,
      pa.id as pause_id,
      pa.time_added as pause_time_added,
      r.id as resume_id,
      r.time_added as resume_time_added,
      aa.artist_id as album_artist_id,
      ta.artist_id as track_artist_id,
      ai.url as album_image_url,
      ai.id as album_image_id,
      ai.width as album_image_width,
      ai.width as album_image_height
      FROM plays p
      JOIN tracks t ON t.id = p.track_id
      JOIN albums a ON a.id = t.album_id
      JOIN album_artists aa ON aa.album_id = a.id
      JOIN track_artists ta ON ta.track_id = t.id
      JOIN artists ar ON ar.id = ta.artist_id OR ar.id = aa.artist_id
      LEFT JOIN pauses pa ON pa.play_id = p.id
      LEFT JOIN resumes r ON r.play_id = p.id
      JOIN album_images ai ON ai.album_id = a.id
      WHERE ((time_started >= ? AND time_started <= ?) OR (time_ended >= ? AND time_ended <= ?))
      ''', [fromTime, toTime, fromTime, toTime]);
    Map<String, Artist> artists = {};
    Map<String, Album> albums = {};
    Map<String, Track> tracks = {};
    Map<String, Play> plays = {};
    Map<int, AlbumCover> covers = {};
    Map<String, Pause> pauses = {};
    Map<String, Resume> resumes = {};
    for (Map<String, dynamic> row in data) {
      if (!albums.containsKey(row['album_id'])) {
        Album album = Album(row['album_id'], row['album_name'], [], []);
        albums[album.id] = album;
      }
      if (!tracks.containsKey(row['track_id'])) {
        Track track = Track(row['track_id'], row['track_name'], [], albums[row['album_id']], []);
        tracks[track.id] = track;
      }
      if (!artists.containsKey(row['artist_id'])) {
        Artist artist = Artist(row['artist_id'], row['artist_name']);
        artists[artist.id] = artist;
      }
      if (row['album_artist_id'] == row['artist_id'] && albums.containsKey(row['album_id'])) {
        albums[row['album_id']].artists.add(artists[row['artist_id']]);
      }
      if (row['track_artist_id'] == row['artist_id'] && tracks.containsKey(row['track_id'])) {
        tracks[row['track_id']].artists.add(artists[row['artist_id']]);
      }
      if (row['album_image_id'] != null && !covers.containsKey(row['album_image_id'])) {
        AlbumCover cover = AlbumCover(row['album_image_url'], row['album_image_width'], row['album_image_height']);
        albums[row['album_id']].covers.add(cover);
        covers[row['album_image_id']] = cover;
      }
      if (!plays.containsKey(row['play_id'])) {
        Play play = Play(row['play_id'], tracks[row['track_id']], row['play_time_started'], row['play_time_ended'], [], []);
        plays[play.id] = play;
        play.track.plays.add(play);
      }
      if (!pauses.containsKey(row['pause_id']) && row['pause_id'] != null) {
        Pause pause = Pause(row['pause_id'], plays[row['play_id']], row['pause_time_added']);
        pauses[pause.id] = pause;
        pause.play.pauses.add(pause);
      }
      if (!resumes.containsKey(row['resume_id']) && row['resume_id'] != null) {
        Resume resume = Resume(row['resume_id'], plays[row['play_id']], row['resume_time_added']);
        resumes[resume.id] = resume;
        resume.play.resumes.add(resume);
      }
    }
    Map<String, Collage> collages = await this.getCollages(tracks);
    return APIData(artists, albums, tracks, plays, collages);
  }

  Future<Collage> addCollage(String name) async {
    String collageId = randomString(36);
    await db.insert(
      'collages',
      {'name': name, 'id': collageId},
    );
    return Collage(collageId, name);
  }

  Future<void> addTrackToCollage(Collage collage, Track track) async {
    await db.insert(
      'collage_track_adds',
      {'track_id': track.id, 'collage_id': collage.id},
    );
  }

  Future<Map<String, Collage>> getCollages(Map tracksMap) async {
    List<Map> collageRows = await db.rawQuery('SELECT * FROM collages');
    List<Map> collageTrackRows = await db.rawQuery('SELECT * FROM collage_track_adds');
    Map<String, Collage> collages = {};
    for (Map collageRow in collageRows) {
      Collage c = Collage(collageRow['id'], collageRow['name']);
      collages[c.id] = c;
    }
    for (Map collageTrackRow in collageTrackRows) {
      Track track = tracksMap[collageTrackRow['track_id']];
      collages[collageTrackRow['collage_id']].tracks.add(track);
    }
    return collages;
  }
  
  Future<int> getFirstPlayTime() async {
    List<Map<String, dynamic>> result = await db.rawQuery('SELECT time_started FROM plays ORDER BY time_started LIMIT 1');
    return result[0]['time_started'];
  }

  Future<List<Map<String, dynamic>>> getPlays() async {
    List<Map<String, dynamic>> plays = await db.rawQuery('SELECT * FROM plays');
    return plays;
  }

  Future<int> getPlayCount() async {
    var data = await this.db.rawQuery('SELECT COUNT(*) FROM plays');
    return Sqflite.firstIntValue(data);
  }

  Future<List<int>> getPlayTimes() async {
    List<Map> playMaps = await db.rawQuery('SELECT time_started FROM plays ORDER BY time_started');
    List<int> times = [];
    for (Map playMap in playMaps) {
      times.add(playMap['time_started']);
    }
    return times;
  }

  Future<Map<String, dynamic>> getPlayAtTime(int time) async {
    List<Map> playMaps = await db.rawQuery('SELECT * FROM plays WHERE time_started = ?', [time]);
    return playMaps[0];
  }
}

class JsonStorage {
  final String filename;

  JsonStorage(this.filename);
  
  Future<void> store(String name, dynamic value) async {
    String externalStoragePath = (await getExternalStorageDirectory()).path;
    File file = File(externalStoragePath + '/' + filename);
    if (file.existsSync()) {
      Map<String, dynamic> data = json.decode(await file.readAsString());
      data[name] = value;
      await file.writeAsString(json.encode(data));
    } else {
      Map<String, dynamic> data = {name: value};
      await file.writeAsString(json.encode(data));
    }
  }

  Future<dynamic> fetch(String name, dynamic defaultValue) async {
    String externalStoragePath = (await getExternalStorageDirectory()).path;
    File file = File(externalStoragePath + '/' + filename);
    if (!file.existsSync())
      return defaultValue;
    Map<String, dynamic> data = json.decode(await file.readAsString());
    if (!data.containsKey(name)) {
      return defaultValue;
    }
    return data[name];
  }
}

class APIClient {
  FlutterSecureStorage secureStorage;
  String accessToken, refreshToken;
  int accessTokenExpiryTime;
  DbProvider dbProvider;
  JsonStorage jsonStorage = JsonStorage(kDebugMode ? 'debug_storage.json' : 'storage.json');
  APIData _data;

  APIClient() {
    this.secureStorage = new FlutterSecureStorage();
  }

  Future<void> saveAuthData() async {
    await this.secureStorage.write(
      key: kDebugMode ? 'debug_refresh_token' : 'refresh_token',
      value: this.refreshToken
    );
    await this.secureStorage.write(
      key: kDebugMode ? 'debug_access_token' : 'access_token',
      value: this.accessToken
    );
    await this.secureStorage.write(
      key: kDebugMode ? 'debug_access_token_expiry_time' : 'access_token_expiry_time',
      value: this.accessTokenExpiryTime.toString()
    );
  }

  Future<void> loadAuthData() async {
    Map<String, String> accessValues = await this.secureStorage.readAll();
    String accessToken = accessValues[kDebugMode ? 'debug_access_token' : 'access_token'];
    if (accessToken != null) {
      this.accessToken = accessToken;
      this.refreshToken = accessValues[kDebugMode ? 'debug_refresh_token' : 'refresh_token'];
      this.accessTokenExpiryTime = int.parse(
        accessValues[kDebugMode ? 'debug_access_token_expiry_time' : 'access_token_expiry_time']
      );
    }
  }

  Future<void> init() async {
    //await secureStorage.deleteAll();
    this.dbProvider = DbProvider();
    await this.dbProvider.open();
    await this.loadAuthData();
  }

  Future<bool> fetchAccessTokenIfExpired() async {
    if (this.accessTokenExpiryTime < DateTime.now().millisecondsSinceEpoch) {
      return await this.fetchAccessToken();
    }
    return true;
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

  Future<bool> fetchAccessToken() async {
    http.Response r = await http.post(BACKEND + "/api/refresh", body: {
        'refresh_token': this.refreshToken,
      }, headers: {
        'Authorization': 'Bearer ${this.refreshToken}',
      }
    );
    if (r.statusCode != 200)
      return false;
    Map<String, dynamic> rJson = json.decode(r.body);
    this.accessToken = rJson['access_token'];
    this.accessTokenExpiryTime =
      new DateTime.now().millisecondsSinceEpoch + 30 * 60 * 1000; // after 30 minutes
    await this.saveAuthData();
    return true;
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
    String accessToken = rJson['access_token']['id'];
    String refreshToken = rJson['refresh_token']['id'];
    int expiryTime = DateTime.now().millisecondsSinceEpoch + 30 * 60 * 1000;
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.accessTokenExpiryTime = expiryTime;
    await this.saveAuthData();
    return true;
  }

  bool hasAccessToken() {
    return this.accessToken != null;
  }

  bool hasData() {
    return this._data != null;
  }

  APIData get data {
    return this._data;
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

  Future<void> fetchAllData() async {
    final now = DateTime.now();
    return this._fetchData(0, now.millisecondsSinceEpoch);
  }

  Future<void> fetchThisMonthData() async {
    final now = DateTime.now();
    int beginningOfMonth = new DateTime(now.year, now.month).millisecondsSinceEpoch;
    return this._fetchData(beginningOfMonth, now.millisecondsSinceEpoch);
  }

  Future<void> fetchNewData() async {
    int lastFetchTime = await this.jsonStorage.fetch('last_fetch_time', 0);
    DateTime now = DateTime.now();
    bool success = await this.fetchData(DateTime.fromMillisecondsSinceEpoch(lastFetchTime), now);
    if (success) {
      await this.jsonStorage.store('last_fetch_time', now.millisecondsSinceEpoch);
    }
    print(success);
  }

  Future<bool> fetchData(DateTime fromTime, DateTime toTime) async {
    return await this._fetchData(fromTime.millisecondsSinceEpoch, toTime.millisecondsSinceEpoch);
  }

  Future<bool> _fetchData(int fromTime, int toTime) async {
    http.Response r;
    try {
      if (!await this.fetchAccessTokenIfExpired()) {
        return false;
      }
      r = await http.get(
        BACKEND + '/api/data?from_time=' + fromTime.toString() + "&to_time=" + toTime.toString(),
        headers: {
          'Authorization': 'Bearer ${this.accessToken}'
        }
      );
    } catch (_) {
      return false;
    }

    Map<String, Play> plays = {};
    Map<String, Artist> artists = {};
    Map<String, Track> tracks = {};
    Map<String, Album> albums = {};

    Map<String, dynamic> jsonData = json.decode(r.body);
    List<dynamic> playsJson = jsonData['plays'];
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
    Map<String, Collage> collages = await this.dbProvider.getCollages(tracks);
    this._data = APIData(artists, albums, tracks, plays, collages);
    await this.saveData();
    return true;
  }

  Future<void> saveData() async {
    await this.dbProvider.addData(this._data);
  }

  Future<void> loadData(DateTime fromTime, DateTime toTime) async {
    this._data = await this.dbProvider.getData(fromTime.millisecondsSinceEpoch, toTime.millisecondsSinceEpoch);
  }

  Future<APIData> getData(DateTime fromTime, DateTime toTime) async {
    return await this.dbProvider.getData(fromTime.millisecondsSinceEpoch, toTime.millisecondsSinceEpoch);
  }

  Future<Collage> addCollage(String name) async {
    Collage c = await this.dbProvider.addCollage(name);
    this.data.collages[c.id] = c;
    return c;
  }

  Future<bool> addTrackToCollage(Collage collage, Track track) async {
    if (collage.tracks.contains(track)) {
      return false;
    }
    await this.dbProvider.addTrackToCollage(collage, track);
    collage.tracks.add(track);
    return true;
  }

  Future<void> updateBackendWithCollages() async {
    int lastUpdateTime = await this.jsonStorage.fetch('last_collage_update_time', 0);
  }

  Future<DateTime> getFirstPlayDateTime() async {
    int time = await this.dbProvider.getFirstPlayTime();
    return DateTime.fromMillisecondsSinceEpoch(time);
  }

  Future<int> getPlayCount() async {
    return await this.dbProvider.getPlayCount();
  }

  Future<Play> getPlayAtDateTime(DateTime dateTime) async {
    APIData data = await this.dbProvider.getData(dateTime.millisecondsSinceEpoch, dateTime.millisecondsSinceEpoch);
    Play play = data.plays.values.elementAt(0);
    return play;
  }

  Future<List<DateTime>> getPlayDateTimes() async {
    List<int> times = await this.dbProvider.getPlayTimes();
    List<DateTime> dateTimes = [];
    for (int time in times) {
      dateTimes.add(DateTime.fromMillisecondsSinceEpoch(time));
    }
    return dateTimes;
  }
}

class APIData {
  Map<String, Artist> artists;
  Map<String, Album> albums;
  Map<String, Track> tracks;
  Map<String, Play> plays;
  Map<String, Collage> collages;

  APIData(this.artists, this.albums, this.tracks, this.plays, this.collages);

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
            tracksMsPlayed[track] += msPlayed;
          } else {
            tracksMsPlayed[track] = msPlayed;
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

  DateTime firstPlayDateTime() {
    DateTime firstPlayDateTime = null;
    for (Play play in this.plays.values) {
      if (firstPlayDateTime == null || firstPlayDateTime.isAfter(play.startDateTime())) {
        firstPlayDateTime = play.startDateTime();
      }
    }
    return firstPlayDateTime;
  }
  DateTime lastPlayDateTime() {
    DateTime lastPlayDateTime = null;
    for (Play play in this.plays.values) {
      if (lastPlayDateTime == null || lastPlayDateTime.isBefore(play.startDateTime())) {
        lastPlayDateTime = play.startDateTime();
      }
    }
    return lastPlayDateTime;
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
