import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../database/database.dart';
import '../../state/settings.dart';
import '../hooks/use_list_query_paging_controller.dart';
import '../items.dart';
import '../lists.dart';

class LibraryAlbumsPage extends HookConsumerWidget {
  const LibraryAlbumsPage({
    required this.onAlbumPressed,
    required this.onArtistPressed,
    super.key,
  });

  final void Function(String albumId) onAlbumPressed;
  final void Function(String artistId) onArtistPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagingController = useLibraryPagingController(
      ref,
      libraryTabIndex: 0,
      getItems: (query) {
        final db = ref.read(databaseProvider);
        final sourceId = ref.read(sourceIdProvider);

        return ref.read(offlineModeProvider)
            ? db.albumsListDownloaded(sourceId, query).get()
            : db.albumsList(sourceId, query).get();
      },
    );

    return PagedGridQueryView(
      pagingController: pagingController,
      refreshSyncAll: true,
      itemBuilder: (context, item, index, size) => AlbumCard(
        album: item,
        style:
            size == GridSize.small ? CardStyle.imageOnly : CardStyle.withText,
        onTap: () => onAlbumPressed(item.id),
        onArtistPressed: onArtistPressed,
      ),
    );
  }
}
