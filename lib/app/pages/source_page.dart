import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../database/database.dart';
import '../../log.dart';
import '../../models/settings.dart';
import '../../services/settings_service.dart';
import '../items.dart';
import '../snackbars.dart';

class SourcePage extends HookConsumerWidget {
  final int? id;

  const SourcePage({
    super.key,
    this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(
      settingsServiceProvider.select(
        (value) => value.sources.singleWhereOrNull((e) => e.id == id)
            as SubsonicSettings?,
      ),
    );
    final form = useState(GlobalKey<FormState>()).value;
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    final isSaving = useState(false);
    final isDeleting = useState(false);

    final name = LabeledTextField(
      label: localizations.settingsServersFieldsName,
      initialValue: source?.name,
      required: true,
    );
    final address = LabeledTextField(
      label: localizations.settingsServersFieldsAddress,
      initialValue: source?.address.toString(),
      keyboardType: TextInputType.url,
      autofillHints: const [AutofillHints.url],
      required: true,
      validator: (value, label) {
        if (!value!.contains(RegExp(r'https?:\/\/'))) {
          return '$label must be a valid URL';
        }
        return null;
      },
    );
    final username = LabeledTextField(
      label: localizations.settingsServersFieldsUsername,
      initialValue: source?.username,
      autofillHints: const [AutofillHints.username],
      required: true,
    );
    final password = LabeledTextField(
      label: localizations.settingsServersFieldsPassword,
      initialValue: source?.password,
      obscureText: true,
      autofillHints: const [AutofillHints.password],
      required: true,
    );

    final forcePlaintextPassword = useState(!(source?.useTokenAuth ?? true));
    final forcePlaintextSwitch = SwitchListTile(
      value: forcePlaintextPassword.value,
      title:
          Text(localizations.settingsServersOptionsForcePlaintextPasswordTitle),
      subtitle: forcePlaintextPassword.value
          ? Text(
              localizations
                  .settingsServersOptionsForcePlaintextPasswordDescriptionOn,
            )
          : Text(
              localizations
                  .settingsServersOptionsForcePlaintextPasswordDescriptionOff,
            ),
      onChanged: (value) => forcePlaintextPassword.value = value,
    );

    return PopScope(
      canPop: !isSaving.value && !isDeleting.value,
      child: Scaffold(
        appBar: AppBar(),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (source != null && source.isActive != true)
              FloatingActionButton(
                backgroundColor: theme.colorScheme.tertiaryContainer,
                foregroundColor: theme.colorScheme.onTertiaryContainer,
                onPressed: !isSaving.value && !isDeleting.value
                    ? () async {
                        try {
                          isDeleting.value = true;
                          await ref
                              .read(settingsServiceProvider.notifier)
                              .deleteSource(source.id);
                        } finally {
                          isDeleting.value = false;
                        }
                      }
                    : null,
                child: isDeleting.value
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      )
                    : const Icon(Icons.delete_forever_rounded),
              ),
            const SizedBox(width: 12),
            FloatingActionButton.extended(
              heroTag: null,
              icon: isSaving.value
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(localizations.settingsServersActionsSave),
              onPressed: !isSaving.value && !isDeleting.value
                  ? () async {
                      if (!form.currentState!.validate()) {
                        return;
                      }

                      try {
                        isSaving.value = true;
                        if (source != null) {
                          await ref
                              .read(settingsServiceProvider.notifier)
                              .updateSource(
                                source.copyWith(
                                  name: name.value,
                                  address: Uri.parse(address.value),
                                  username: username.value,
                                  password: password.value,
                                  useTokenAuth: !forcePlaintextPassword.value,
                                ),
                              );
                        } else {
                          await ref
                              .read(settingsServiceProvider.notifier)
                              .createSource(
                                SourcesCompanion.insert(
                                  name: name.value,
                                  address: Uri.parse(address.value),
                                ),
                                SubsonicSourcesCompanion.insert(
                                  features: IList(),
                                  username: username.value,
                                  password: password.value,
                                  useTokenAuth:
                                      Value(!forcePlaintextPassword.value),
                                ),
                              );
                        }
                      } catch (e, st) {
                        if (!context.mounted) return;
                        showErrorSnackbar(context, e.toString());
                        log.severe('Saving source', e, st);
                      } finally {
                        isSaving.value = false;
                      }
                    }
                  : null,
            ),
          ],
        ),
        body: Form(
          key: form,
          child: AutofillGroup(
            child: ListView(
              children: [
                const SizedBox(height: 96 - kToolbarHeight),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    source == null
                        ? localizations.settingsServersActionsAdd
                        : localizations.settingsServersActionsEdit,
                    style: theme.textTheme.displaySmall,
                  ),
                ),
                name,
                address,
                username,
                password,
                const SizedBox(height: 24),
                forcePlaintextSwitch,
                const FabPadding(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LabeledTextField extends HookConsumerWidget {
  final String label;
  final String? initialValue;
  final bool obscureText;
  final bool required;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final String? Function(String? value, String label)? validator;

  // ignore: prefer_const_constructors_in_immutables
  LabeledTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.autofillHints,
    this.required = false,
  });

  late final TextEditingController _controller;

  String get value => _controller.text;

  String? _requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return '$label is required';
    }

    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    _controller = useTextEditingController(text: initialValue);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(label, style: theme.textTheme.titleMedium),
          TextFormField(
            controller: _controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            autofillHints: autofillHints,
            validator: (value) {
              String? error;

              if (required) {
                error = _requiredValidator(value);
                if (error != null) {
                  return error;
                }
              }

              if (validator != null) {
                return validator!(value, label);
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
