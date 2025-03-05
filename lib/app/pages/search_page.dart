import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../database/database.dart';
import '../../models/music.dart';
import '../../models/query.dart';
import '../../models/support.dart';
import '../../services/audio_service.dart';
import '../../state/music.dart';
import '../../state/settings.dart';
import '../items.dart';
import 'songs_page.dart';

part 'search_page.g.dart';

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String? build() {
    return null;
  }

  void setQuery(String query) {
    state = query;
  }
}

@riverpod
FutureOr<SearchResults> searchResult(Ref ref) async {
  final query = ref.watch(searchQueryProvider);
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  final ftsQuery = '(source_id : $sourceId) AND (- source_id : "$query"*)';

  final songRowIds = await db.searchSongs(ftsQuery, 5, 0).get();
  final songs = await db.songsInRowIds(songRowIds).get();
  final albumRowIds = await db.searchAlbums(ftsQuery, 5, 0).get();
  final albums = await db.albumsInRowIds(albumRowIds).get();
  final artistRowIds = await db.searchArtists(ftsQuery, 5, 0).get();
  final artists = await db.artistsInRowIds(artistRowIds).get();

  return SearchResults(
    songs: songs.lock,
    albums: albums.lock,
    artists: artists.lock,
  );
}

class SearchPage extends HookConsumerWidget {
  const SearchPage({
    required this.onAlbumPressed,
    required this.onArtistPressed,
    super.key,
  });

  final void Function(String albumId) onAlbumPressed;
  final void Function(String artistId) onArtistPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultProvider).valueOrNull;

    return KeyboardDismissOnTap(
      dismissOnCapturedTaps: true,
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            reverse: true,
            slivers: [
              const SliverToBoxAdapter(child: _SearchBar()),
              if (results != null && results.songs.isNotEmpty)
                _SongsSection(
                  songs: results.songs,
                  onAlbumPressed: onAlbumPressed,
                  onArtistPressed: onArtistPressed,
                ),
              if (results != null && results.albums.isNotEmpty)
                _AlbumsSection(
                  albums: results.albums,
                  onAlbumPressed: onAlbumPressed,
                  onArtistPressed: onArtistPressed,
                ),
              if (results != null && results.artists.isNotEmpty)
                _ArtistsSection(
                  artists: results.artists,
                  onArtistPressed: onArtistPressed,
                ),
              if (results != null)
                const SliverPadding(padding: EdgeInsets.only(top: 96)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends HookConsumerWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(text: '');

    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Container(
      color: ElevationOverlay.applySurfaceTint(
        theme.colorScheme.surface,
        theme.colorScheme.surfaceTint,
        1,
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          right: 24,
          left: 24,
          bottom: 24,
          top: 8,
        ),
        child: IgnoreKeyboardDismiss(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: localizations.searchInputPlaceholder,
            ),
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).setQuery(value);
            },
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends HookConsumerWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title, style: theme.textTheme.headlineMedium),
    );
  }
}

class _Section extends HookConsumerWidget {
  final String title;
  final Iterable<Widget> children;

  const _Section({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 16),
        ...children.toList().reversed,
        _SectionHeader(title: title),
      ]),
    );
  }
}

class _SongsSection extends HookConsumerWidget {
  final IList<Song>? songs;
  final void Function(String albumId) onAlbumPressed;
  final void Function(String artistId) onArtistPressed;

  const _SongsSection({
    required this.songs,
    required this.onAlbumPressed,
    required this.onArtistPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);

    return _Section(
      title: localizations.resourcesSongName(100),
      children: (songs ?? <Song>[]).map(
        (song) => QueueContext(
          type: QueueContextType.album,
          id: song.albumId!,
          child: SongListTile(
            song: song,
            image: true,
            onTap: () async {
              const query = ListQuery(sort: SortBy(column: 'disc, track'));
              final albumSongs = await ref.read(
                albumSongsListProvider(song.albumId!, query).future,
              );

              ref.read(audioControlProvider).playSongs(
                    context: QueueContextType.album,
                    contextId: song.albumId!,
                    shuffle: true,
                    startIndex: albumSongs.indexOf(song),
                    query: query,
                    getSongs: (query) => ref.read(
                      albumSongsListProvider(song.albumId!, query).future,
                    ),
                  );
            },
            onAlbumPressed: onAlbumPressed,
            onArtistPressed: onArtistPressed,
          ),
        ),
      ),
    );
  }
}

class _AlbumsSection extends HookConsumerWidget {
  final IList<Album>? albums;
  final void Function(String albumId) onAlbumPressed;
  final void Function(String artistId) onArtistPressed;

  const _AlbumsSection({
    required this.albums,
    required this.onAlbumPressed,
    required this.onArtistPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);

    return _Section(
      title: localizations.resourcesAlbumName(100),
      children: (albums ?? <Album>[]).map(
        (album) => AlbumListTile(
          album: album,
          onTap: () => onAlbumPressed(album.id),
          onArtistPressed: onArtistPressed,
        ),
      ),
    );
  }
}

class _ArtistsSection extends HookConsumerWidget {
  final IList<Artist>? artists;
  final void Function(String artistId) onArtistPressed;

  const _ArtistsSection({
    required this.artists,
    required this.onArtistPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);

    return _Section(
      title: localizations.resourcesArtistName(100),
      children: (artists ?? <Artist>[]).map(
        (artist) => ArtistListTile(
          artist: artist,
          onTap: () => onArtistPressed(artist.id),
        ),
      ),
    );
  }
}
