import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../database/database.dart';
import '../../models/query.dart';
import '../../models/support.dart';
import '../../services/audio_service.dart';
import '../../state/settings.dart';
import '../hooks/use_list_query_paging_controller.dart';
import '../items.dart';
import '../lists.dart';
import 'library_page.dart';
import 'songs_page.dart';

class LibrarySongsPage extends HookConsumerWidget {
  const LibrarySongsPage({
    required this.onAlbumPressed,
    required this.onArtistPressed,
    required this.onAlbumsPressed,
    super.key,
  });

  final void Function(String albumId) onAlbumPressed;
  final void Function(String artistId) onArtistPressed;
  final VoidCallback onAlbumsPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioControlProvider);

    final query = ref.watch(
      libraryListQueryProvider(3).select(
        (value) => value.query,
      ),
    );

    final getSongs = useCallback(
      (ListQuery query) {
        final db = ref.read(databaseProvider);
        final sourceId = ref.read(sourceIdProvider);

        return ref.read(offlineModeProvider)
            ? db.songsListDownloaded(sourceId, query).get()
            : db.songsList(sourceId, query).get();
      },
      [],
    );

    final play = useCallback(
      ({int? index, bool? shuffle}) => audio.playSongs(
        query: query,
        getSongs: getSongs,
        startIndex: index,
        context: QueueContextType.song,
        shuffle: shuffle,
      ),
      [query, getSongs],
    );

    final pagingController = useLibraryPagingController(
      ref,
      libraryTabIndex: 3,
      getItems: getSongs,
    );

    return PagedListQueryView(
      pagingController: pagingController,
      refreshSyncAll: true,
      itemBuilder: (context, item, index) => QueueContext(
        type: QueueContextType.song,
        child: SongListTile(
          song: item,
          image: true,
          onTap: () => play(index: index),
          onAlbumPressed: onAlbumPressed,
          onArtistPressed: onArtistPressed,
        ),
      ),
    );
  }
}
