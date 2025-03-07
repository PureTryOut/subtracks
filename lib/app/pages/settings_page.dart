import 'dart:math';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../log.dart';
import '../../models/support.dart';
import '../../services/settings_service.dart';
import '../../state/init.dart';
import '../../state/settings.dart';
import '../dialogs.dart';

const kHorizontalPadding = 16.0;

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({
    required this.onSourcePressed,
    super.key,
  });

  final void Function([int sourceId]) onSourcePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: ListView(
        children: [
          const SizedBox(height: 96),
          _SectionHeader(localizations.settingsServersName),
          _Sources(onSourcePressed: onSourcePressed),
          _SectionHeader(localizations.settingsNetworkName),
          const _Network(),
          _SectionHeader(localizations.settingsAboutName),
          _About(),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final List<Widget> children;

  const _Section({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...children,
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kHorizontalPadding),
            child: Text(
              title,
              style: theme.textTheme.displaySmall,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Network extends StatelessWidget {
  const _Network();

  @override
  Widget build(BuildContext context) {
    return const _Section(
      children: [
        _OfflineMode(),
        _MaxBitrateWifi(),
        _MaxBitrateMobile(),
        _StreamFormat(),
      ],
    );
  }
}

class _About extends HookConsumerWidget {
  _About();

  final _homepage = Uri.parse('https://github.com/austinried/subtracks');
  final _donate = Uri.parse('https://ko-fi.com/austinried');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final pkg = ref.watch(packageInfoProvider).requireValue;

    return _Section(
      children: [
        ListTile(
          title: const Text('subtracks'),
          subtitle: Text(localizations.settingsAboutVersion(pkg.version)),
        ),
        ListTile(
          title: Text(localizations.settingsAboutActionsLicenses),
          // trailing: const Icon(Icons.open_in_new_rounded),
          onTap: () {},
        ),
        ListTile(
          title: Text(localizations.settingsAboutActionsProjectHomepage),
          subtitle: Text(_homepage.toString()),
          trailing: const Icon(Icons.open_in_new_rounded),
          onTap: () => launchUrl(
            _homepage,
            mode: LaunchMode.externalApplication,
          ),
        ),
        ListTile(
          title: Text(localizations.settingsAboutActionsSupport),
          subtitle: Text(_donate.toString()),
          trailing: const Icon(Icons.open_in_new_rounded),
          onTap: () => launchUrl(
            _donate,
            mode: LaunchMode.externalApplication,
          ),
        ),
        const SizedBox(height: 12),
        const _ShareLogsButton(),
      ],
    );
  }
}

class _ShareLogsButton extends StatelessWidget {
  const _ShareLogsButton();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.share),
          label: Text(localizations.settingsAboutShareLogs),
          onPressed: () async {
            final files = await logFiles();
            if (files.isEmpty) return;

            if (!context.mounted) return;
            final value = await showDialog<String>(
              context: context,
              builder: (context) => MultipleChoiceDialog<String>(
                title: localizations.settingsAboutChooseLog,
                current: files.first.path,
                options: files
                    .map(
                      (e) => MultiChoiceOption.string(
                        title: p.basename(e.path),
                        option: e.path,
                      ),
                    )
                    .toIList(),
              ),
            );

            if (value == null) return;
            Share.shareXFiles(
              [XFile(value, mimeType: 'text/plain')],
              subject: 'Logs from subtracks: ${String.fromCharCodes(
                List.generate(8, (_) => Random().nextInt(26) + 65),
              )}',
            );
          },
        ),
      ],
    );
  }
}

class _MaxBitrateWifi extends HookConsumerWidget {
  const _MaxBitrateWifi();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bitrate = ref.watch(
      settingsServiceProvider.select(
        (value) => value.app.maxBitrateWifi,
      ),
    );
    final localizations = AppLocalizations.of(context);

    return _MaxBitrateOption(
      title: localizations.settingsNetworkOptionsMaxBitrateWifiTitle,
      bitrate: bitrate,
      onChange: (value) {
        ref.read(settingsServiceProvider.notifier).setMaxBitrateWifi(value);
      },
    );
  }
}

class _MaxBitrateMobile extends HookConsumerWidget {
  const _MaxBitrateMobile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bitrate = ref.watch(
      settingsServiceProvider.select(
        (value) => value.app.maxBitrateMobile,
      ),
    );
    final localizations = AppLocalizations.of(context);

    return _MaxBitrateOption(
      title: localizations.settingsNetworkOptionsMaxBitrateMobileTitle,
      bitrate: bitrate,
      onChange: (value) {
        ref.read(settingsServiceProvider.notifier).setMaxBitrateMobile(value);
      },
    );
  }
}

class _MaxBitrateOption extends HookConsumerWidget {
  final String title;
  final int bitrate;
  final void Function(int value) onChange;

  const _MaxBitrateOption({
    required this.title,
    required this.bitrate,
    required this.onChange,
  });

  static const options = [0, 24, 32, 64, 96, 128, 192, 256, 320];

  String _bitrateText(AppLocalizations l, int bitrate) {
    return bitrate == 0
        ? l.settingsNetworkValuesUnlimitedKbps
        : l.settingsNetworkValuesKbps(bitrate.toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);

    return ListTile(
      title: Text(title),
      subtitle: Text(_bitrateText(localizations, bitrate)),
      onTap: () async {
        final value = await showDialog<int>(
          context: context,
          builder: (context) => MultipleChoiceDialog<int>(
            title: title,
            current: bitrate,
            options: options
                .map(
                  (opt) => MultiChoiceOption.int(
                    title: _bitrateText(localizations, opt),
                    option: opt,
                  ),
                )
                .toIList(),
          ),
        );

        if (value != null) {
          onChange(value);
        }
      },
    );
  }
}

class _StreamFormat extends HookConsumerWidget {
  const _StreamFormat();

  static const options = ['', 'mp3', 'opus', 'ogg'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamFormat = ref.watch(
      settingsServiceProvider.select((value) => value.app.streamFormat),
    );
    final localizations = AppLocalizations.of(context);

    return ListTile(
      title: Text(localizations.settingsNetworkOptionsStreamFormat),
      subtitle: Text(
        streamFormat ??
            localizations.settingsNetworkOptionsStreamFormatServerDefault,
      ),
      onTap: () async {
        final value = await showDialog<String>(
          context: context,
          builder: (context) => MultipleChoiceDialog<String>(
            title: localizations.settingsNetworkOptionsStreamFormat,
            current: streamFormat ?? '',
            options: options
                .map(
                  (opt) => MultiChoiceOption.string(
                    title: opt == ''
                        ? localizations
                            .settingsNetworkOptionsStreamFormatServerDefault
                        : opt,
                    option: opt,
                  ),
                )
                .toIList(),
          ),
        );

        if (value != null) {
          ref
              .read(settingsServiceProvider.notifier)
              .setStreamFormat(value == '' ? null : value);
        }
      },
    );
  }
}

class _OfflineMode extends HookConsumerWidget {
  const _OfflineMode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(offlineModeProvider);
    final localizations = AppLocalizations.of(context);

    return SwitchListTile(
      value: offline,
      title: Text(localizations.settingsNetworkOptionsOfflineMode),
      subtitle: offline
          ? Text(localizations.settingsNetworkOptionsOfflineModeOn)
          : Text(localizations.settingsNetworkOptionsOfflineModeOff),
      onChanged: (value) {
        ref.read(offlineModeProvider.notifier).setMode(value);
      },
    );
  }
}

class _Sources extends HookConsumerWidget {
  const _Sources({required this.onSourcePressed});

  final void Function([int sourceId]) onSourcePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(
      settingsServiceProvider.select(
        (value) => value.sources,
      ),
    );
    final activeSource = ref.watch(
      settingsServiceProvider.select(
        (value) => value.activeSource,
      ),
    );

    final localizations = AppLocalizations.of(context);

    return _Section(
      children: [
        for (var source in sources)
          RadioListTile<int>(
            value: source.id,
            groupValue: activeSource?.id,
            onChanged: (value) {
              ref
                  .read(settingsServiceProvider.notifier)
                  .setActiveSource(source.id);
            },
            title: Text(source.name),
            subtitle: Text(
              source.address.toString(),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
            secondary: IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => onSourcePressed(source.id),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: Text(localizations.settingsServersActionsAdd),
              onPressed: () => onSourcePressed(),
            ),
          ],
        ),
        // TODO: remove
        if (kDebugMode)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add TEST'),
                onPressed: () {
                  ref
                      .read(settingsServiceProvider.notifier)
                      .addTestSource('TEST');
                },
              ),
            ],
          ),
      ],
    );
  }
}
