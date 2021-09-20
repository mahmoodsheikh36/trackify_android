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
