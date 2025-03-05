// ignore_for_file: use_key_in_widget_constructors

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'pages/artist_page.dart';
import 'pages/bottom_nav_page.dart';
import 'pages/browse_page.dart';
import 'pages/library_albums_page.dart';
import 'pages/library_artists_page.dart';
import 'pages/library_page.dart';
import 'pages/library_playlists_page.dart';
import 'pages/library_songs_page.dart';
import 'pages/now_playing_page.dart';
import 'pages/search_page.dart';
import 'pages/settings_page.dart';
import 'pages/songs_page.dart';
import 'pages/source_page.dart';

part 'app_router.gr.dart';

const kCustomTransitionBuilder = TransitionsBuilders.slideRightWithFade;
const kCustomTransitionDuration = 160;

final itemRoutes = [
  CustomRoute(
    path: 'album/:id',
    page: AlbumSongsRoute.page,
    transitionsBuilder: kCustomTransitionBuilder,
    duration: const Duration(milliseconds: kCustomTransitionDuration),
    reverseDuration: const Duration(milliseconds: kCustomTransitionDuration),
  ),
  CustomRoute(
    path: 'artist/:id',
    page: ArtistRoute.page,
    transitionsBuilder: kCustomTransitionBuilder,
    duration: const Duration(milliseconds: kCustomTransitionDuration),
    reverseDuration: const Duration(milliseconds: kCustomTransitionDuration),
  ),
  CustomRoute(
    path: 'playlist/:id',
    page: PlaylistSongsRoute.page,
    transitionsBuilder: kCustomTransitionBuilder,
    duration: const Duration(milliseconds: kCustomTransitionDuration),
    reverseDuration: const Duration(milliseconds: kCustomTransitionDuration),
  ),
  CustomRoute(
    path: 'genre/:genre',
    page: GenreSongsRoute.page,
    transitionsBuilder: kCustomTransitionBuilder,
    duration: const Duration(milliseconds: kCustomTransitionDuration),
    reverseDuration: const Duration(milliseconds: kCustomTransitionDuration),
  ),
];

@RoutePage()
class EmptyRouterPage extends StatelessWidget {
  const EmptyRouterPage({super.key});

  @override
  Widget build(BuildContext context) => const AutoRouter();
}

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/',
          page: EmptyRouterRoute.page,
          children: [
            AutoRoute(
              path: '',
              page: BottomNavTabsRoute.page,
              children: [
                AutoRoute(
                  path: 'library',
                  page: LibraryTabsRoute.page,
                  children: [
                    AutoRoute(
                      path: 'albums',
                      page: LibraryAlbumsRoute.page,
                    ),
                    AutoRoute(
                      path: 'artists',
                      page: LibraryArtistsRoute.page,
                    ),
                    AutoRoute(
                      path: 'playlists',
                      page: LibraryPlaylistsRoute.page,
                    ),
                    AutoRoute(
                      path: 'songs',
                      page: LibrarySongsRoute.page,
                    ),
                  ],
                ),
                AutoRoute(
                  path: 'browse',
                  page: EmptyRouterRoute.page,
                  children: [
                    AutoRoute(
                      path: '',
                      page: BrowseRoute.page,
                    ),
                    ...itemRoutes,
                  ],
                ),
                AutoRoute(
                  path: 'search',
                  page: SearchRoute.page,
                ),
                AutoRoute(path: 'settings', page: SettingsRoute.page),
                ...itemRoutes,
              ],
            ),
            CustomRoute(
              path: 'settings/source/:id',
              page: SourceRoute.page,
              transitionsBuilder: kCustomTransitionBuilder,
              duration: const Duration(milliseconds: kCustomTransitionDuration),
              reverseDuration:
                  const Duration(milliseconds: kCustomTransitionDuration),
            ),
          ],
        ),
        CustomRoute(
          path: '/now-playing',
          page: NowPlayingRoute.page,
          transitionsBuilder: TransitionsBuilders.slideBottom,
          duration: const Duration(milliseconds: 200),
          reverseDuration: const Duration(milliseconds: 160),
        ),
      ];
}

class TabObserver extends AutoRouterObserver {
  final StreamController<String> _controller = StreamController.broadcast();
  Stream<String> get path => _controller.stream;

  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) {
    _controller.add(route.path);
  }

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) {
    _controller.add(route.path);
  }
}
