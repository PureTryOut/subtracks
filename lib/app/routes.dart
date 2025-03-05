import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subtracks/app/pages/artist_page.dart';
import 'package:subtracks/app/pages/bottom_nav_page.dart';
import 'package:subtracks/app/pages/browse_page.dart';
import 'package:subtracks/app/pages/library_page.dart';
import 'package:subtracks/app/pages/now_playing_page.dart';
import 'package:subtracks/app/pages/search_page.dart';
import 'package:subtracks/app/pages/settings_page.dart';
import 'package:subtracks/app/pages/songs_page.dart';
import 'package:subtracks/app/pages/source_page.dart';

part 'routes.g.dart';

@riverpod
GoRouter routes(Ref ref) {
  var rootNavigatorKey = GlobalKey<NavigatorState>();
  var shellNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/library',
    routes: [
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        pageBuilder: (context, state, child) => NoTransitionPage(
          child: BottomNavTabsPage(
            location: state.matchedLocation,
            child: child,
            onCurrentSongPressed: () => context.go('/now-playing'),
            onLibraryPressed: () => context.go('/library'),
            onBrowsePressed: () => context.go('/browse'),
            onSearchPressed: () => context.go('/search'),
            onSettingsPressed: () => context.go('/settings'),
          ),
        ),
        routes: [
          GoRoute(
            path: '/library',
            parentNavigatorKey: shellNavigatorKey,
            builder: (context, state) => LibraryTabsPage(
              onArtistPressed: (String artistId) =>
                  context.go("/browse/artists/$artistId"),
              onPlaylistPressed: (String playlistId) =>
                  context.go("/browse/playlists/$playlistId"),
              onAlbumPressed: (String albumId) =>
                  context.go("/browse/albums/$albumId"),
              onAlbumsPressed: () => context.go("/browse/albums"),
            ),
          ),
          GoRoute(
            path: '/browse',
            parentNavigatorKey: shellNavigatorKey,
            builder: (context, state) => BrowsePage(
              onGenrePressed: (String genreId) =>
                  context.go("/browse/genres/$genreId"),
              onAlbumPressed: (String albumId) =>
                  context.go("/browse/albums/$albumId"),
              onArtistPressed: (String artistId) =>
                  context.go("/browse/artists/$artistId"),
            ),
            routes: [
              GoRoute(
                path: 'genres/:genreId',
                builder: (context, state) {
                  var genreId = state.pathParameters["genreId"]!;

                  return GenreSongsPage(
                    genre: genreId,
                    onAlbumPressed: (String albumId) =>
                        context.go("/browse/albums/$albumId"),
                    onArtistPressed: (String artistId) =>
                        context.go("/browse/artists/$artistId"),
                  );
                },
              ),
              GoRoute(
                path: 'albums/:albumId',
                builder: (context, state) {
                  var albumId = state.pathParameters["albumId"]!;

                  return AlbumSongsPage(
                    id: albumId,
                    onAlbumPressed: (String albumId) =>
                        context.go("/browse/albums/$albumId"),
                    onArtistPressed: (String artistId) =>
                        context.go("/browse/artists/$artistId"),
                  );
                },
              ),
              GoRoute(
                path: 'artists/:artistId',
                builder: (context, state) {
                  var artistId = state.pathParameters["artistId"]!;

                  return ArtistPage(
                    id: artistId,
                    onAlbumPressed: (String albumId) =>
                        context.go("/browse/albums/:albumId"),
                    onArtistPressed: (String artistId) =>
                        context.go("/browse/artists/$artistId"),
                  );
                },
              ),
              GoRoute(
                path: 'playlists/:playlistId',
                builder: (context, state) {
                  var playlistId = state.pathParameters["playlistId"]!;

                  return PlaylistSongsPage(
                    id: playlistId,
                    onAlbumPressed: (String albumId) =>
                        context.go("/browse/albums/$albumId"),
                    onArtistPressed: (String artistId) =>
                        context.go("/browse/artists/$artistId"),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/search',
            parentNavigatorKey: shellNavigatorKey,
            builder: (context, state) => SearchPage(
              onAlbumPressed: (String albumId) =>
                  context.go("/browse/albums/$albumId"),
              onArtistPressed: (String artistId) =>
                  context.go("/browse/artists/$artistId"),
            ),
          ),
          GoRoute(
            path: '/settings',
            parentNavigatorKey: shellNavigatorKey,
            builder: (context, state) => SettingsPage(
              onSourcePressed: ([int? sourceId]) {
                if (sourceId != null) {
                  context.go("/source/$sourceId!");
                  return;
                }

                context.go("/source");
              },
            ),
            routes: [
              GoRoute(
                path: 'source',
                builder: (context, state) => const SourcePage(),
              ),
              GoRoute(
                path: 'source/:sourceId',
                builder: (context, state) {
                  var sourceId = int.parse(state.pathParameters["sourceId"]!);

                  return SourcePage(id: sourceId);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/now-playing',
        builder: (context, state) => NowPlayingPage(
          onAlbumPressed: (String albumId) =>
              context.go("/browse/albums/$albumId"),
          onArtistPressed: (String artistId) =>
              context.go("/browse/artists/$artistId"),
        ),
      ),
    ],
  );
}
