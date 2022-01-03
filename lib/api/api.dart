import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:trackify_android/db/models.dart';
import 'package:trackify_android/db/db.dart';
import 'package:trackify_android/static.dart';

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
  FlutterSecureStorage secureStorage = FlutterSecureStorage();
  String accessToken, refreshToken;
  int accessTokenExpiryTime;
  DbProvider dbProvider = DbProvider();
  JsonStorage jsonStorage = JsonStorage(kDebugMode ? 'debug_storage.json' : 'storage.json');
  APIData _data;

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
    await secureStorage.deleteAll();
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
    http.Response r = await http.get(Uri.parse(BACKEND + '/api/top_users?from_time=' + fromTime.toString() + '&to_time=' + toTime.toString()),
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
    http.Response r = await http.post(Uri.parse(BACKEND + "/api/refresh"), body: {
        'refresh_token': this.refreshToken,
      }, headers: {
        'Authorization': 'Bearer ${this.refreshToken}',
      }
    );
    if (r.statusCode != 200)
      return false;
    Map<String, dynamic> rJson = json.decode(r.body);
    this.accessToken = rJson['access_token']['id'];
    this.accessTokenExpiryTime =
      new DateTime.now().millisecondsSinceEpoch + 30 * 60 * 1000; // after 30 minutes
    await this.saveAuthData();
    return true;
  }

  Future<bool> authenticate(String username, String password) async {
    return await this.fetchRefreshToken(username, password);
  }

  Future<bool> fetchRefreshToken(String username, String password) async {
    http.Response r = await http.post(Uri.parse(BACKEND + "/api/login"), body: {
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
      r = await http.get(Uri.parse(BACKEND + '/api/data?from_time=' + fromTime.toString() + "&to_time=" + toTime.toString()),
        headers: {
          'Authorization': 'Bearer ${this.accessToken}'
        }
      );
    } catch (exception) {
      print(exception);
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
