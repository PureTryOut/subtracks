import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../database/database.dart';
import '../../state/settings.dart';
import '../hooks/use_list_query_paging_controller.dart';
import '../items.dart';
import '../lists.dart';

class LibraryArtistsPage extends HookConsumerWidget {
  const LibraryArtistsPage({
    super.key,
    required this.onArtistPressed,
  });

  final void Function(String artistId) onArtistPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagingController = useLibraryPagingController(
      ref,
      libraryTabIndex: 1,
      getItems: (query) {
        final db = ref.read(databaseProvider);
        final sourceId = ref.read(sourceIdProvider);

        return ref.read(offlineModeProvider)
            ? db.artistsListDownloaded(sourceId, query).get()
            : db.artistsList(sourceId, query).get();
      },
    );

    return PagedListQueryView(
      pagingController: pagingController,
      refreshSyncAll: true,
      itemBuilder: (context, item, index) => ArtistListTile(
        artist: item,
        onTap: () => onArtistPressed(item.id),
      ),
    );
  }
}
