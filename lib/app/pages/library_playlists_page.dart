import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../database/database.dart';
import '../../state/settings.dart';
import '../hooks/use_list_query_paging_controller.dart';
import '../items.dart';
import '../lists.dart';

class LibraryPlaylistsPage extends HookConsumerWidget {
  const LibraryPlaylistsPage({
    required this.onPlaylistPressed,
    super.key,
  });

  final void Function(String playlistId) onPlaylistPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagingController = useLibraryPagingController(
      ref,
      libraryTabIndex: 2,
      getItems: (query) {
        final db = ref.read(databaseProvider);
        final sourceId = ref.read(sourceIdProvider);

        return ref.read(offlineModeProvider)
            ? db.playlistsListDownloaded(sourceId, query).get()
            : db.playlistsList(sourceId, query).get();
      },
    );

    return PagedListQueryView(
      pagingController: pagingController,
      refreshSyncAll: true,
      itemBuilder: (context, item, index) => PlaylistListTile(
        playlist: item,
        onTap: () => onPlaylistPressed(item.id),
      ),
    );
  }
}
