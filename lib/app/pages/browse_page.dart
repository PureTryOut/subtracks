import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../database/database.dart';
import '../../models/music.dart';
import '../../models/query.dart';
import '../../models/support.dart';
import '../../services/audio_service.dart';
import '../../services/cache_service.dart';
import '../../state/music.dart';
import '../../state/settings.dart';
import '../buttons.dart';
import '../images.dart';
import '../items.dart';

part 'browse_page.g.dart';

@riverpod
Stream<List<Album>> albumsCategoryList(
  Ref ref,
  ListQuery opt,
) {
  final db = ref.watch(databaseProvider);
  final sourceId = ref.watch(sourceIdProvider);

  return db.albumsList(sourceId, opt).watch();
}

class BrowsePage extends HookConsumerWidget {
  const BrowsePage({
    required this.onGenrePressed,
    required this.onAlbumPressed,
    required this.onArtistPressed,
    super.key,
  });

  final void Function(String genreId) onGenrePressed;
  final void Function(String albumId) onAlbumPressed;
  final void Function(String artistId) onArtistPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);

    final frequent = ref
        .watch(
          albumsCategoryListProvider(
            const ListQuery(
              page: Pagination(limit: 20),
              sort: SortBy(column: 'frequent_rank'),
              filters: IListConst([
                FilterWith.isNull(column: 'frequent_rank', invert: true),
              ]),
            ),
          ),
        )
        .valueOrNull;
    final recent = ref
        .watch(
          albumsCategoryListProvider(
            const ListQuery(
              page: Pagination(limit: 20),
              sort: SortBy(column: 'recent_rank'),
              filters: IListConst([
                FilterWith.isNull(column: 'recent_rank', invert: true),
              ]),
            ),
          ),
        )
        .valueOrNull;
    final starred = ref
        .watch(
          albumsCategoryListProvider(
            const ListQuery(
              page: Pagination(limit: 20),
              sort: SortBy(column: 'starred'),
              filters: IListConst([
                FilterWith.isNull(column: 'starred', invert: true),
              ]),
            ),
          ),
        )
        .valueOrNull;
    final random = ref
        .watch(
          albumsCategoryListProvider(
            const ListQuery(
              page: Pagination(limit: 20),
              sort: SortBy(column: 'RANDOM()'),
            ),
          ),
        )
        .valueOrNull;

    final genres = ref
        .watch(
          albumGenresProvider(
            const Pagination(
              limit: 20,
            ),
          ),
        )
        .valueOrNull;

    final songs = ref.watch(songsListProvider(const ListQuery())).valueOrNull;

    void onPlayRadioPressed() {
      ref.read(audioControlProvider).playRadio(
            context: QueueContextType.library,
            getSongs: (query) => ref
                .read(databaseProvider)
                .songsList(ref.read(sourceIdProvider), query)
                .get(),
          );
    }

    return Scaffold(
      floatingActionButton: RadioPlayFab(
        onPressed:
            songs != null && songs.isNotEmpty ? onPlayRadioPressed : null,
      ),
      body: CustomScrollView(
        slivers: [
          const SliverSafeArea(
            sliver: SliverPadding(padding: EdgeInsets.only(top: 8)),
          ),
          _GenreCategory(
            title: 'Genres',
            items: genres?.toList() ?? [],
            onGenrePressed: onGenrePressed,
          ),
          _AlbumCategory(
            title: localizations.resourcesSortByFrequentlyPlayed,
            items: frequent ?? [],
            onAlbumPressed: onAlbumPressed,
            onArtistPressed: onArtistPressed,
          ),
          _AlbumCategory(
            title: localizations.resourcesSortByRecentlyPlayed,
            items: recent ?? [],
            onAlbumPressed: onAlbumPressed,
            onArtistPressed: onArtistPressed,
          ),
          _AlbumCategory(
            title: localizations.resourcesFilterStarred,
            items: starred ?? [],
            onAlbumPressed: onAlbumPressed,
            onArtistPressed: onArtistPressed,
          ),
          _AlbumCategory(
            title: localizations.resourcesSortByRandom,
            items: random ?? [],
            onAlbumPressed: onAlbumPressed,
            onArtistPressed: onArtistPressed,
          ),
          const SliverToBoxAdapter(child: FabPadding()),
        ],
      ),
    );
  }
}

class _GenreCategory extends HookConsumerWidget {
  final String title;
  final List<String> items;
  final void Function(String genreId) onGenrePressed;

  const _GenreCategory({
    required this.title,
    required this.items,
    required this.onGenrePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 16),
      sliver: _Category(
        title: title,
        height: 140,
        itemWidth: 140,
        items: items
            .map(
              (genre) => _GenreItem(
                genre: genre,
                onGenrePressed: onGenrePressed,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _GenreItem extends HookConsumerWidget {
  final String genre;
  final void Function(String genreId) onGenrePressed;

  const _GenreItem({
    required this.genre,
    required this.onGenrePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref
        .watch(
          albumsByGenreProvider(
            genre,
            const Pagination(limit: 4),
          ),
        )
        .valueOrNull;
    final cache = ref.watch(cacheServiceProvider);

    final theme = Theme.of(context);

    if (albums == null) {
      return Container();
    }

    return ImageCard(
      onTap: () => onGenrePressed(genre),
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          CardClip(
            child: MultiImage(
              cacheInfo: albums.map((album) => cache.albumArt(album)),
            ),
          ),
          Material(
            type: MaterialType.canvas,
            color: theme.colorScheme.secondaryContainer,
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  genre,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumCategory extends HookConsumerWidget {
  final String title;
  final List<Album> items;

  final void Function(String albumId) onAlbumPressed;
  final void Function(String artistId) onArtistPressed;

  const _AlbumCategory({
    required this.title,
    required this.items,
    required this.onAlbumPressed,
    required this.onArtistPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Category(
      title: title,
      height: 190,
      itemWidth: 140,
      items: items
          .map(
            (album) => AlbumCard(
              album: album,
              onTap: () => onAlbumPressed(album.id),
              onArtistPressed: onArtistPressed,
            ),
          )
          .toList(),
    );
  }
}

class _Category extends HookConsumerWidget {
  final String title;
  final List<Widget> items;
  final double height;
  final double itemWidth;

  const _Category({
    required this.title,
    required this.items,
    required this.height,
    required this.itemWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return MultiSliver(
      children: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              title,
              style: theme.textTheme.headlineMedium,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: height,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) => SizedBox(
                width: itemWidth,
                child: items[index],
              ),
              separatorBuilder: (context, index) => const SizedBox(width: 8),
            ),
          ),
        ),
      ],
    );
  }
}
