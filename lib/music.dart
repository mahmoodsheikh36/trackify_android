class Artist {
  String id;
  String name;
  Artist(this.id, this.name);
}

class Track {
  String id;
  String name;
  List<Artist> artists;
  Track(this.id, this.name, this.artists);
}