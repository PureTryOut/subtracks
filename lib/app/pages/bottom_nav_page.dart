import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../services/settings_service.dart';
import '../../state/settings.dart';
import '../now_playing_bar.dart';

class BottomNavTabsPage extends HookConsumerWidget {
  const BottomNavTabsPage({
    required this.location,
    required this.child,
    required this.onCurrentSongPressed,
    required this.onLibraryPressed,
    required this.onBrowsePressed,
    required this.onSearchPressed,
    required this.onSettingsPressed,
    super.key,
  });

  final String location;
  final Widget child;

  final VoidCallback onCurrentSongPressed;
  final VoidCallback onLibraryPressed;
  final VoidCallback onBrowsePressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    const navElevation = 3.0;

    var activePageIndex = 0;
    if (location.startsWith('/library')) {
      activePageIndex = 0;
    }
    if (location.startsWith('/browse')) {
      activePageIndex = 1;
    }
    if (location.startsWith('/search')) {
      activePageIndex = 2;
    }
    if (location.startsWith('/settings')) {
      activePageIndex = 3;
    }

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          systemNavigationBarColor: ElevationOverlay.applySurfaceTint(
            theme.colorScheme.surface,
            theme.colorScheme.surfaceTint,
            navElevation,
          ),
          statusBarColor: Colors.transparent,
        ),
        child: Stack(
          alignment: AlignmentDirectional.bottomStart,
          children: [
            child,
            const OfflineIndicator(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        navElevation: navElevation,
        activeIndex: activePageIndex,
        onCurrentSongPressed: onCurrentSongPressed,
        onLibraryPressed: onLibraryPressed,
        onBrowsePressed: onBrowsePressed,
        onSearchPressed: onSearchPressed,
        onSettingsPressed: onSettingsPressed,
      ),
    );
  }
}

class OfflineIndicator extends HookConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(offlineModeProvider);
    final testing = useState(false);

    if (!offline) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 20,
        bottom: 20,
      ),
      child: FilledButton.tonal(
        style: const ButtonStyle(
          padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.zero,
          ),
          fixedSize: WidgetStatePropertyAll<Size>(
            Size(42, 42),
          ),
          minimumSize: WidgetStatePropertyAll<Size>(
            Size(42, 42),
          ),
        ),
        onPressed: () async {
          testing.value = true;
          await ref.read(offlineModeProvider.notifier).setMode(false);
          testing.value = false;
        },
        child: testing.value
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Padding(
                padding: EdgeInsets.only(left: 2, bottom: 2),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 20,
                ),
              ),
      ),
    );
  }
}

class _BottomNavBar extends HookConsumerWidget {
  final double navElevation;
  final int activeIndex;

  final VoidCallback onCurrentSongPressed;
  final VoidCallback onLibraryPressed;
  final VoidCallback onBrowsePressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onSettingsPressed;

  const _BottomNavBar({
    required this.navElevation,
    required this.activeIndex,
    required this.onCurrentSongPressed,
    required this.onLibraryPressed,
    required this.onBrowsePressed,
    required this.onSearchPressed,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconTheme = IconTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        NowPlayingBar(onPressed: onCurrentSongPressed),
        NavigationBar(
          elevation: navElevation,
          height: 50,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          selectedIndex: activeIndex,
          onDestinationSelected: (index) {
            // TODO: replace this with a proper first-time setup flow
            final hasActiveSource = ref.read(
              settingsServiceProvider.select(
                (value) => value.activeSource != null,
              ),
            );

            if (!hasActiveSource) {
              onSettingsPressed();
            }

            switch (index) {
              case 0:
                onLibraryPressed();
                break;
              case 1:
                onBrowsePressed();
                break;
              case 2:
                onSearchPressed();
                break;
              case 3:
                onSettingsPressed();
            }
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.music_note),
              label: 'Library',
            ),
            NavigationDestination(
              icon: Builder(
                builder: (context) {
                  return SvgPicture.asset(
                    'assets/tag_FILL0_wght400_GRAD0_opsz24.svg',
                    colorFilter: ColorFilter.mode(
                      iconTheme.color!
                          .withValues(alpha: iconTheme.opacity ?? 1),
                      BlendMode.srcIn,
                    ),
                    height: 28,
                  );
                },
              ),
              label: 'Browse',
            ),
            const NavigationDestination(
              icon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ],
    );
  }
}
