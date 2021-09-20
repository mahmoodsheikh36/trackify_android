import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import 'package:trackify_android/db/models.dart';
import 'package:trackify_android/api/api.dart';
import 'package:trackify_android/utils.dart';

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
