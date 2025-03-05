import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/database.dart';
import '../models/music.dart';
import '../models/query.dart';
import '../models/support.dart';
import 'settings.dart';

part 'music.g.dart';

@riverpod
Stream<Artist> artist(Ref ref, String id) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db.artistById(sourceId, id).watchSingle();
}

@riverpod
Stream<Album> album(Ref ref, String id) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db.albumById(sourceId, id).watchSingle();
}

@riverpod
Stream<ListDownloadStatus> albumDownloadStatus(
  Ref ref,
  String id,
) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db.albumDownloadStatus(sourceId, id).watchSingle();
}

@riverpod
Stream<ListDownloadStatus> playlistDownloadStatus(
  Ref ref,
  String id,
) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db.playlistDownloadStatus(sourceId, id).watchSingle();
}

@riverpod
Stream<Song> song(Ref ref, String id) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db.songById(sourceId, id).watchSingle();
}

@riverpod
Future<List<Song>> albumSongsList(
  Ref ref,
  String id,
  ListQuery opt,
) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db.albumSongsList(SourceId(sourceId: sourceId, id: id), opt).get();
}

@riverpod
Future<List<Song>> songsByAlbumList(
  Ref ref,
  ListQuery opt,
) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db.songsByAlbumList(sourceId, opt).get();
}

@riverpod
Stream<Playlist> playlist(Ref ref, String id) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db.playlistById(sourceId, id).watchSingle();
}

@riverpod
Future<List<Song>> playlistSongsList(
  Ref ref,
  String id,
  ListQuery opt,
) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db.playlistSongsList(SourceId(sourceId: sourceId, id: id), opt).get();
}

@riverpod
Future<List<Album>> albumsInIds(Ref ref, IList<String> ids) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db.albumsInIds(sourceId, ids.toList()).get();
}

@riverpod
Stream<IList<Album>> albumsByArtistId(Ref ref, String id) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db
      .albumsByArtistId(sourceId, id)
      .watch()
      .map((event) => event.toIList());
}

@riverpod
Stream<IList<String>> albumGenres(Ref ref, Pagination page) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db
      .albumGenres(sourceId, page.limit, page.offset)
      .watch()
      .map((event) => event.withNullsRemoved().toIList());
}

@riverpod
Stream<IList<Album>> albumsByGenre(
  Ref ref,
  String genre,
  Pagination page,
) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db
      .albumsByGenre(sourceId, genre, page.limit, page.offset)
      .watch()
      .map((event) => event.toIList());
}

@riverpod
Stream<int> songsByGenreCount(Ref ref, String genre) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db.songsByGenreCount(sourceId, genre).watchSingle();
}

@riverpod
Stream<IList<Song>> songsList(Ref ref, ListQuery opt) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db
      .songsList(sourceId, opt)
      .watch()
      .map((event) => event.withNullsRemoved().toIList());
}
