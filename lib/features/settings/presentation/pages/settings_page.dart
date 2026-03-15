import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lightshot_parser_mobile/core/theme/app_theme.dart';
import 'package:lightshot_parser_mobile/core/widgets/app_snack_bar.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/utils/download_source_texts.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_cubit.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_state.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/cubit/settings_state.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/utils/settings_form_validators.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/utils/settings_page_texts.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';

enum _SettingsTextField {
  wantedNum,
  lightshotStartingId,
  imgurStartingId,
  proxyAddress,
  proxyPort,
  proxyLogin,
  proxyPassword,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Duration _autosaveDelay = Duration(milliseconds: 500);
  static const Duration _autosaveStatusResetDelay = Duration(seconds: 2);

  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final Map<_SettingsTextField, Timer> _debounceTimers =
      <_SettingsTextField, Timer>{};
  final Map<_SettingsTextField, FocusNode> _focusNodes =
      <_SettingsTextField, FocusNode>{};

  late final TextEditingController _wantedNumController;
  late final TextEditingController _lightshotStartingIdController;
  late final TextEditingController _imgurStartingIdController;
  late final TextEditingController _proxyAddressController;
  late final TextEditingController _proxyPortController;
  late final TextEditingController _proxyLoginController;
  late final TextEditingController _proxyPasswordController;
  Timer? _statusResetTimer;

  @override
  void initState() {
    super.initState();
    final draft = context.read<SettingsCubit>().state.draft;
    _wantedNumController =
        TextEditingController(text: draft.wantedNumOfImages.toString());
    _lightshotStartingIdController =
        TextEditingController(text: draft.lightshot.startingId);
    _imgurStartingIdController =
        TextEditingController(text: draft.imgur.startingId);
    _proxyAddressController =
        TextEditingController(text: draft.proxySettings.address);
    _proxyPortController =
        TextEditingController(text: draft.proxySettings.port);
    _proxyLoginController =
        TextEditingController(text: draft.proxySettings.login);
    _proxyPasswordController =
        TextEditingController(text: draft.proxySettings.password);

    for (final field in _SettingsTextField.values) {
      final node = FocusNode();
      node.addListener(() {
        if (!node.hasFocus) {
          unawaited(_commitField(field));
        }
      });
      _focusNodes[field] = node;
    }
  }

  @override
  void dispose() {
    _statusResetTimer?.cancel();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _scrollController.dispose();
    _wantedNumController.dispose();
    _lightshotStartingIdController.dispose();
    _imgurStartingIdController.dispose();
    _proxyAddressController.dispose();
    _proxyPortController.dispose();
    _proxyLoginController.dispose();
    _proxyPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SettingsCubit, SettingsState>(
          listener: (context, state) {
            if (state.saveStatus == SettingsSaveStatus.saving) {
              _statusResetTimer?.cancel();
            } else if (state.saveStatus == SettingsSaveStatus.success ||
                state.saveStatus == SettingsSaveStatus.failure) {
              _scheduleSaveStatusReset();
            }

            if (state.saveStatus == SettingsSaveStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                buildAppSnackBar(
                  message: S.of(context).pleaseEnterTheCorrectData,
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
        BlocListener<GalleryCubit, GalleryState>(
          listener: (context, state) {
            if (state.feedback == GalleryFeedback.reindexed) {
              ScaffoldMessenger.of(context).showSnackBar(
                buildAppSnackBar(message: S.of(context).recreateDatabase),
              );
              context.read<GalleryCubit>().clearFeedback();
            } else if (state.feedback == GalleryFeedback.reclassified) {
              ScaffoldMessenger.of(context).showSnackBar(
                buildAppSnackBar(message: S.of(context).reclassificationDone),
              );
              context.read<GalleryCubit>().clearFeedback();
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).settings),
          centerTitle: true,
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            final selectedSource = state.draft.selectedSource;
            return SafeArea(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Form(
                        key: _formKey,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 980;
                            return Column(
                              key: ValueKey(
                                isWide
                                    ? 'settings-desktop-layout'
                                    : 'settings-mobile-layout',
                              ),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _SettingsHero(saveStatus: state.saveStatus),
                                const SizedBox(height: AppSpacing.xl),
                                if (isWide)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _buildGeneralCard(context),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            _buildSourceCard(
                                              context,
                                              state,
                                              selectedSource,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xl),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _buildProxyCard(context, state),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  _buildGeneralCard(context),
                                  const SizedBox(height: AppSpacing.lg),
                                  _buildSourceCard(
                                    context,
                                    state,
                                    selectedSource,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  _buildProxyCard(context, state),
                                ],
                                const SizedBox(height: AppSpacing.lg),
                                BlocBuilder<GalleryCubit, GalleryState>(
                                  builder: (context, galleryState) {
                                    return _MaintenanceCard(
                                      isReclassifying:
                                          galleryState.isReclassifying,
                                      processedCount: galleryState
                                          .reclassificationProcessedCount,
                                      totalCount: galleryState
                                          .reclassificationTotalCount,
                                      onReclassifyAll: _confirmReclassifyAll,
                                      onReclassifyDisabledOnly:
                                          _confirmReclassifyDisabledOnly,
                                      onRebuildIndex: _confirmRebuildIndex,
                                      onClearImages: _confirmClearImages,
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  FocusNode _focusNode(_SettingsTextField field) => _focusNodes[field]!;

  void _scheduleCommit(_SettingsTextField field) {
    _debounceTimers[field]?.cancel();
    _debounceTimers[field] = Timer(
      _autosaveDelay,
      () => unawaited(_commitField(field)),
    );
  }

  void _scheduleSaveStatusReset() {
    _statusResetTimer?.cancel();
    _statusResetTimer = Timer(_autosaveStatusResetDelay, () {
      if (!mounted) {
        return;
      }
      context.read<SettingsCubit>().clearSaveStatus();
    });
  }

  Future<void> _commitField(_SettingsTextField field) async {
    _debounceTimers[field]?.cancel();
    final cubit = context.read<SettingsCubit>();
    final draft = cubit.state.draft;

    switch (field) {
      case _SettingsTextField.wantedNum:
        final text = _wantedNumController.text;
        final error = SettingsFormValidators.validateWantedNumOfImages(
          context,
          text,
        );
        if (error != null) {
          return;
        }
        final value = int.parse(text);
        if (value != draft.wantedNumOfImages) {
          cubit.setWantedNumOfImages(value);
          await cubit.save();
        }
      case _SettingsTextField.lightshotStartingId:
        final text = _lightshotStartingIdController.text;
        final error = SettingsFormValidators.validateStartingUrl(
          context,
          useRandomAddress: draft.lightshot.useRandomAddress,
          useNewAddresses: draft.lightshot.useNewAddresses,
          value: text,
        );
        if (error != null) {
          return;
        }
        if (text != draft.lightshot.startingId) {
          cubit.setStartingUrl(text);
          await cubit.save();
        }
      case _SettingsTextField.imgurStartingId:
        final text = _imgurStartingIdController.text;
        final error = SettingsFormValidators.validateImgurStartingId(
          context,
          useRandomAddress: draft.imgur.useRandomAddress,
          idLength: draft.imgur.idLength,
          value: text,
        );
        if (error != null) {
          return;
        }
        if (text != draft.imgur.startingId) {
          cubit.setImgurStartingId(text);
          await cubit.save();
        }
      case _SettingsTextField.proxyAddress:
        final text = _proxyAddressController.text;
        if (!draft.proxySettings.enabled) {
          return;
        }
        final error =
            SettingsFormValidators.validateProxyAddress(context, text);
        if (error != null) {
          return;
        }
        if (text != draft.proxySettings.address) {
          cubit.setProxyAddress(text);
          await _saveProxySectionIfValid();
        }
      case _SettingsTextField.proxyPort:
        final text = _proxyPortController.text;
        if (!draft.proxySettings.enabled) {
          return;
        }
        final error = SettingsFormValidators.validateProxyPort(context, text);
        if (error != null) {
          return;
        }
        if (text != draft.proxySettings.port) {
          cubit.setProxyPort(text);
          await _saveProxySectionIfValid();
        }
      case _SettingsTextField.proxyLogin:
        final text = _proxyLoginController.text;
        if (!draft.proxySettings.enabled ||
            !draft.proxySettings.useAuthentication) {
          return;
        }
        final error = SettingsFormValidators.validateRequired(
          text,
          S.of(context).pleaseEnterTheProxyLogin,
        );
        if (error != null) {
          return;
        }
        if (text != draft.proxySettings.login) {
          cubit.setProxyLogin(text);
          await _saveProxySectionIfValid();
        }
      case _SettingsTextField.proxyPassword:
        final text = _proxyPasswordController.text;
        if (!draft.proxySettings.enabled ||
            !draft.proxySettings.useAuthentication) {
          return;
        }
        final error = SettingsFormValidators.validateRequired(
          text,
          S.of(context).pleaseEnterTheProxyPassword,
        );
        if (error != null) {
          return;
        }
        if (text != draft.proxySettings.password) {
          cubit.setProxyPassword(text);
          await _saveProxySectionIfValid();
        }
    }
  }

  Future<void> _onSourceChanged(DownloadSource? value) async {
    if (value == null) {
      return;
    }
    context.read<SettingsCubit>().setSelectedSource(value);
    await context.read<SettingsCubit>().save();
  }

  Future<void> _onNeuralRecognitionChanged(bool value) async {
    final cubit = context.read<SettingsCubit>();
    cubit.setNeuralRecognitionEnabled(value);
    await cubit.save();
  }

  Future<void> _onUseNewAddressesChanged(bool value) async {
    final maxLength = value ? 12 : 6;
    if (_lightshotStartingIdController.text.length > maxLength) {
      _lightshotStartingIdController.text =
          _lightshotStartingIdController.text.substring(0, maxLength);
      _lightshotStartingIdController.selection = TextSelection.collapsed(
        offset: _lightshotStartingIdController.text.length,
      );
    }
    final cubit = context.read<SettingsCubit>();
    cubit.setUseNewAddresses(value);
    cubit.setStartingUrl(_lightshotStartingIdController.text);
    await _saveLightshotSectionIfValid();
  }

  Future<void> _onUseRandomLightshotChanged(bool value) async {
    final cubit = context.read<SettingsCubit>();
    if (value) {
      _lightshotStartingIdController.clear();
      cubit.setUseRandomAddress(true);
      cubit.setStartingUrl('');
      await cubit.save();
      return;
    }
    cubit.setUseRandomAddress(false);
    cubit.setStartingUrl(_lightshotStartingIdController.text);
    await _saveLightshotSectionIfValid();
  }

  Future<void> _onImgurLengthChanged(int? value) async {
    if (value == null) {
      return;
    }
    if (_imgurStartingIdController.text.length > value) {
      _imgurStartingIdController.text =
          _imgurStartingIdController.text.substring(0, value);
      _imgurStartingIdController.selection = TextSelection.collapsed(
        offset: _imgurStartingIdController.text.length,
      );
    }
    final cubit = context.read<SettingsCubit>();
    cubit.setImgurIdLength(value);
    cubit.setImgurStartingId(_imgurStartingIdController.text);
    await _saveImgurSectionIfValid();
  }

  Future<void> _onUseRandomImgurChanged(bool value) async {
    final cubit = context.read<SettingsCubit>();
    if (value) {
      _imgurStartingIdController.clear();
      cubit.setImgurUseRandomAddress(true);
      cubit.setImgurStartingId('');
      await cubit.save();
      return;
    }
    cubit.setImgurUseRandomAddress(false);
    cubit.setImgurStartingId(_imgurStartingIdController.text);
    await _saveImgurSectionIfValid();
  }

  Future<void> _onProxyEnabledChanged(bool value) async {
    final cubit = context.read<SettingsCubit>();
    cubit.setUseProxy(value);
    if (!value) {
      await cubit.save();
      return;
    }
    await _saveProxySectionIfValid();
  }

  Future<void> _onProxyAuthChanged(bool value) async {
    final cubit = context.read<SettingsCubit>();
    cubit.setUseProxyAuth(value);
    if (!value) {
      await cubit.save();
      return;
    }
    await _saveProxySectionIfValid();
  }

  Future<void> _saveLightshotSectionIfValid() async {
    final draft = context.read<SettingsCubit>().state.draft;
    final error = SettingsFormValidators.validateStartingUrl(
      context,
      useRandomAddress: draft.lightshot.useRandomAddress,
      useNewAddresses: draft.lightshot.useNewAddresses,
      value: _lightshotStartingIdController.text,
    );
    if (error == null) {
      await context.read<SettingsCubit>().save();
    }
  }

  Future<void> _saveImgurSectionIfValid() async {
    final draft = context.read<SettingsCubit>().state.draft;
    final error = SettingsFormValidators.validateImgurStartingId(
      context,
      useRandomAddress: draft.imgur.useRandomAddress,
      idLength: draft.imgur.idLength,
      value: _imgurStartingIdController.text,
    );
    if (error == null) {
      await context.read<SettingsCubit>().save();
    }
  }

  Future<void> _saveProxySectionIfValid() async {
    final draft = context.read<SettingsCubit>().state.draft;
    if (!draft.proxySettings.enabled) {
      await context.read<SettingsCubit>().save();
      return;
    }

    final addressError = SettingsFormValidators.validateProxyAddress(
      context,
      _proxyAddressController.text,
    );
    final portError = SettingsFormValidators.validateProxyPort(
      context,
      _proxyPortController.text,
    );
    final loginError = !draft.proxySettings.useAuthentication
        ? null
        : SettingsFormValidators.validateRequired(
            _proxyLoginController.text,
            S.of(context).pleaseEnterTheProxyLogin,
          );
    final passwordError = !draft.proxySettings.useAuthentication
        ? null
        : SettingsFormValidators.validateRequired(
            _proxyPasswordController.text,
            S.of(context).pleaseEnterTheProxyPassword,
          );

    if (addressError == null &&
        portError == null &&
        loginError == null &&
        passwordError == null) {
      await context.read<SettingsCubit>().save();
    }
  }

  Future<void> _confirmRebuildIndex() async {
    final confirmed = await _showConfirmationDialog(
      title: SettingsPageTexts.confirmRebuildTitle(context),
      body: SettingsPageTexts.confirmRebuildBody(context),
      confirmLabel: S.of(context).recreateDatabase,
      destructive: false,
    );
    if (confirmed && mounted) {
      await context.read<GalleryCubit>().rebuildIndex();
    }
  }

  Future<void> _confirmReclassifyAll() async {
    final confirmed = await _showConfirmationDialog(
      title: S.of(context).reclassifyAllImages,
      body: S.of(context).reclassifyAllImagesConfirmationBody,
      confirmLabel: S.of(context).reclassifyAllImages,
      destructive: false,
    );
    if (confirmed && mounted) {
      await context.read<GalleryCubit>().reclassifyAllImages();
    }
  }

  Future<void> _confirmReclassifyDisabledOnly() async {
    final confirmed = await _showConfirmationDialog(
      title: S.of(context).reclassifyDisabledImages,
      body: S.of(context).reclassifyDisabledImagesConfirmationBody,
      confirmLabel: S.of(context).reclassifyDisabledImages,
      destructive: false,
    );
    if (confirmed && mounted) {
      await context.read<GalleryCubit>().reclassifyAllImages(
            disabledOnly: true,
          );
    }
  }

  Future<void> _confirmClearImages() async {
    final confirmed = await _showConfirmationDialog(
      title: SettingsPageTexts.confirmClearTitle(context),
      body: SettingsPageTexts.confirmClearBody(context),
      confirmLabel: S.of(context).clearImages,
      destructive: true,
    );
    if (confirmed && mounted) {
      await context.read<GalleryCubit>().clearImages();
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String body,
    required String confirmLabel,
    required bool destructive,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).cancel),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Widget _buildGeneralCard(BuildContext context) {
    final wideFields = MediaQuery.sizeOf(context).width >= 720;
    final draft = context.watch<SettingsCubit>().state.draft;
    final selectedSource = draft.selectedSource;

    Widget sourceField() {
      return DropdownButtonFormField<DownloadSource>(
        key: const ValueKey('settings-source-field'),
        initialValue: selectedSource,
        decoration: InputDecoration(
          labelText: DownloadSourceTexts.sourceLabel(context),
        ),
        items: DownloadSource.values
            .map(
              (source) => DropdownMenuItem<DownloadSource>(
                value: source,
                child: Text(DownloadSourceTexts.sourceName(context, source)),
              ),
            )
            .toList(growable: false),
        onChanged: (value) => unawaited(_onSourceChanged(value)),
      );
    }

    Widget wantedNumField() {
      return TextFormField(
        key: const ValueKey('settings-wanted-num-field'),
        controller: _wantedNumController,
        focusNode: _focusNode(_SettingsTextField.wantedNum),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: S.of(context).numberOfImagesToDownload,
          hintText: S.of(context).enterTheNumberOfImagesToDownload,
        ),
        maxLength: 5,
        keyboardType: TextInputType.number,
        validator: (value) =>
            SettingsFormValidators.validateWantedNumOfImages(context, value),
        onChanged: (_) => _scheduleCommit(_SettingsTextField.wantedNum),
      );
    }

    return _SectionCard(
      sectionKey: const ValueKey('general-settings-card'),
      title: SettingsPageTexts.generalTitle(context),
      subtitle: SettingsPageTexts.generalBody(context),
      child: Column(
        children: [
          wideFields
              ? Row(
                  children: [
                    Expanded(child: sourceField()),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: wantedNumField()),
                  ],
                )
              : Column(
                  children: [
                    sourceField(),
                    const SizedBox(height: AppSpacing.md),
                    wantedNumField(),
                  ],
                ),
          const SizedBox(height: AppSpacing.md),
          _AdaptiveSwitchTile(
            key: const ValueKey('settings-neural-recognition-switch'),
            value: draft.isNeuralRecognitionEnabled,
            onChanged: (value) => unawaited(_onNeuralRecognitionChanged(value)),
            title: S.of(context).settingsAiRecognitionTitle,
            subtitle: S.of(context).settingsAiRecognitionDescription,
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard(
    BuildContext context,
    SettingsState state,
    DownloadSource selectedSource,
  ) {
    final draft = state.draft;
    final lightshot = draft.lightshot;
    final imgur = draft.imgur;

    return _SectionCard(
      sectionKey: const ValueKey('source-settings-card'),
      title: SettingsPageTexts.sourceTitle(context, selectedSource),
      subtitle: SettingsPageTexts.sourceBody(context, selectedSource),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: selectedSource == DownloadSource.lightshot
            ? Column(
                key: const ValueKey('lightshot-settings-group'),
                children: [
                  _AdaptiveSwitchTile(
                    value: lightshot.useNewAddresses,
                    onChanged: (value) => unawaited(
                      _onUseNewAddressesChanged(value),
                    ),
                    title: S.of(context).useNewAddresses,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _AdaptiveSwitchTile(
                    value: lightshot.useRandomAddress,
                    onChanged: (value) => unawaited(
                      _onUseRandomLightshotChanged(value),
                    ),
                    title: S.of(context).useRandomAddresses,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _lightshotStartingIdController,
                    focusNode: _focusNode(
                      _SettingsTextField.lightshotStartingId,
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    enabled: !lightshot.useRandomAddress,
                    decoration: InputDecoration(
                      labelText: S.of(context).startingAddress,
                      hintText: S.of(context).enterTheStartingAddress,
                      helperText: lightshot.useRandomAddress
                          ? SettingsPageTexts.randomHint(context)
                          : null,
                    ),
                    maxLength: lightshot.idLength,
                    validator: (value) =>
                        SettingsFormValidators.validateStartingUrl(
                      context,
                      useRandomAddress: lightshot.useRandomAddress,
                      useNewAddresses: lightshot.useNewAddresses,
                      value: value,
                    ),
                    onChanged: (_) => _scheduleCommit(
                      _SettingsTextField.lightshotStartingId,
                    ),
                  ),
                ],
              )
            : Column(
                key: const ValueKey('imgur-settings-group'),
                children: [
                  DropdownButtonFormField<int>(
                    key: const ValueKey('settings-imgur-length-field'),
                    initialValue: imgur.idLength,
                    decoration: InputDecoration(
                      labelText: DownloadSourceTexts.imgurIdLength(context),
                    ),
                    items: const [5, 7]
                        .map(
                          (value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value'),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => unawaited(
                      _onImgurLengthChanged(value),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _AdaptiveSwitchTile(
                    value: imgur.useRandomAddress,
                    onChanged: (value) => unawaited(
                      _onUseRandomImgurChanged(value),
                    ),
                    title: S.of(context).useRandomAddresses,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _imgurStartingIdController,
                    focusNode: _focusNode(_SettingsTextField.imgurStartingId),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    enabled: !imgur.useRandomAddress,
                    decoration: InputDecoration(
                      labelText: DownloadSourceTexts.startingId(context),
                      hintText: DownloadSourceTexts.enterTheStartingId(context),
                      helperText: imgur.useRandomAddress
                          ? SettingsPageTexts.randomHint(context)
                          : null,
                    ),
                    maxLength: imgur.idLength,
                    validator: (value) =>
                        SettingsFormValidators.validateImgurStartingId(
                      context,
                      useRandomAddress: imgur.useRandomAddress,
                      idLength: imgur.idLength,
                      value: value,
                    ),
                    onChanged: (_) => _scheduleCommit(
                      _SettingsTextField.imgurStartingId,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProxyCard(BuildContext context, SettingsState state) {
    final proxy = state.draft.proxySettings;
    final canUseRows = MediaQuery.sizeOf(context).width >= 760;

    Widget addressField() {
      return TextFormField(
        key: const ValueKey('settings-proxy-address-field'),
        controller: _proxyAddressController,
        focusNode: _focusNode(_SettingsTextField.proxyAddress),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: S.of(context).proxyAddress,
          hintText: S.of(context).enterTheProxyAddress,
        ),
        validator: (value) =>
            SettingsFormValidators.validateProxyAddress(context, value),
        onChanged: (_) => _scheduleCommit(_SettingsTextField.proxyAddress),
      );
    }

    Widget portField() {
      return TextFormField(
        key: const ValueKey('settings-proxy-port-field'),
        controller: _proxyPortController,
        focusNode: _focusNode(_SettingsTextField.proxyPort),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: S.of(context).proxyPort,
          hintText: S.of(context).enterTheProxyPort,
        ),
        validator: (value) =>
            SettingsFormValidators.validateProxyPort(context, value),
        onChanged: (_) => _scheduleCommit(_SettingsTextField.proxyPort),
      );
    }

    Widget loginField() {
      return TextFormField(
        key: const ValueKey('settings-proxy-login-field'),
        controller: _proxyLoginController,
        focusNode: _focusNode(_SettingsTextField.proxyLogin),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: S.of(context).proxyLogin,
          hintText: S.of(context).enterTheProxyLogin,
        ),
        validator: (value) => SettingsFormValidators.validateRequired(
          value,
          S.of(context).pleaseEnterTheProxyLogin,
        ),
        onChanged: (_) => _scheduleCommit(_SettingsTextField.proxyLogin),
      );
    }

    Widget passwordField() {
      return TextFormField(
        key: const ValueKey('settings-proxy-password-field'),
        controller: _proxyPasswordController,
        focusNode: _focusNode(_SettingsTextField.proxyPassword),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        obscureText: true,
        decoration: InputDecoration(
          labelText: S.of(context).proxyPassword,
          hintText: S.of(context).enterTheProxyPassword,
        ),
        validator: (value) => SettingsFormValidators.validateRequired(
          value,
          S.of(context).pleaseEnterTheProxyPassword,
        ),
        onChanged: (_) => _scheduleCommit(_SettingsTextField.proxyPassword),
      );
    }

    return _SectionCard(
      sectionKey: const ValueKey('proxy-settings-card'),
      title: SettingsPageTexts.proxyTitle(context),
      subtitle: SettingsPageTexts.proxyBody(context),
      child: Column(
        children: [
          _AdaptiveSwitchTile(
            value: proxy.enabled,
            onChanged: (value) => unawaited(_onProxyEnabledChanged(value)),
            title: S.of(context).useProxy,
          ),
          if (proxy.enabled) ...[
            const SizedBox(height: AppSpacing.sm),
            _AdaptiveSwitchTile(
              value: proxy.useAuthentication,
              onChanged: (value) => unawaited(_onProxyAuthChanged(value)),
              title: S.of(context).useProxyAuth,
            ),
            const SizedBox(height: AppSpacing.md),
            canUseRows
                ? Row(
                    children: [
                      Expanded(child: addressField()),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: portField()),
                    ],
                  )
                : Column(
                    children: [
                      addressField(),
                      const SizedBox(height: AppSpacing.md),
                      portField(),
                    ],
                  ),
            if (proxy.useAuthentication) ...[
              const SizedBox(height: AppSpacing.md),
              canUseRows
                  ? Row(
                      children: [
                        Expanded(child: loginField()),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: passwordField()),
                      ],
                    )
                  : Column(
                      children: [
                        loginField(),
                        const SizedBox(height: AppSpacing.md),
                        passwordField(),
                      ],
                    ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({
    required this.saveStatus,
  });

  final SettingsSaveStatus saveStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('settings-hero'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF9F3), Color(0xFFF1DDD2), Color(0xFFE8C8B9)],
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).settings,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 30,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  SettingsPageTexts.pageSubtitle(context),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
          _AutosaveBadge(saveStatus: saveStatus),
        ],
      ),
    );
  }
}

class _AutosaveBadge extends StatelessWidget {
  const _AutosaveBadge({
    required this.saveStatus,
  });

  final SettingsSaveStatus saveStatus;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (saveStatus) {
      SettingsSaveStatus.idle => (
          SettingsPageTexts.autosaveIdle(context),
          AppColors.accent,
          Icons.cloud_done_outlined,
        ),
      SettingsSaveStatus.saving => (
          SettingsPageTexts.autosaveSaving(context),
          AppColors.warning,
          Icons.autorenew_rounded,
        ),
      SettingsSaveStatus.success => (
          SettingsPageTexts.autosaveSaved(context),
          AppColors.success,
          Icons.check_circle_outline,
        ),
      SettingsSaveStatus.failure => (
          SettingsPageTexts.autosaveError(context),
          AppColors.error,
          Icons.error_outline,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({
    required this.isReclassifying,
    required this.processedCount,
    required this.totalCount,
    required this.onReclassifyAll,
    required this.onReclassifyDisabledOnly,
    required this.onRebuildIndex,
    required this.onClearImages,
  });

  final bool isReclassifying;
  final int processedCount;
  final int totalCount;
  final Future<void> Function() onReclassifyAll;
  final Future<void> Function() onReclassifyDisabledOnly;
  final Future<void> Function() onRebuildIndex;
  final Future<void> Function() onClearImages;

  String _reclassificationLabel(BuildContext context) {
    if (!isReclassifying) {
      return S.of(context).reclassifyAllImages;
    }
    return S.of(context).reclassificationProgress(
          processedCount,
          totalCount,
        );
  }

  @override
  Widget build(BuildContext context) {
    final canUseRows = MediaQuery.sizeOf(context).width >= 720;

    return _SectionCard(
      sectionKey: const ValueKey('maintenance-card'),
      title: SettingsPageTexts.maintenanceTitle(context),
      subtitle: SettingsPageTexts.maintenanceBody(context),
      child: canUseRows
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('maintenance-reclassify-button'),
                    onPressed: isReclassifying
                        ? null
                        : () => unawaited(onReclassifyAll()),
                    icon: isReclassifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                    label: Text(_reclassificationLabel(context)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey(
                      'maintenance-reclassify-disabled-button',
                    ),
                    onPressed: isReclassifying
                        ? null
                        : () => unawaited(onReclassifyDisabledOnly()),
                    icon: isReclassifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high_rounded),
                    label: Text(
                      isReclassifying
                          ? _reclassificationLabel(context)
                          : S.of(context).reclassifyDisabledImages,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('maintenance-rebuild-button'),
                    onPressed: () => unawaited(onRebuildIndex()),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(S.of(context).recreateDatabase),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('maintenance-clear-button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => unawaited(onClearImages()),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(S.of(context).clearImages),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('maintenance-reclassify-button'),
                  onPressed: isReclassifying
                      ? null
                      : () => unawaited(onReclassifyAll()),
                  icon: isReclassifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(_reclassificationLabel(context)),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  key: const ValueKey('maintenance-reclassify-disabled-button'),
                  onPressed: isReclassifying
                      ? null
                      : () => unawaited(onReclassifyDisabledOnly()),
                  icon: isReclassifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high_rounded),
                  label: Text(
                    isReclassifying
                        ? _reclassificationLabel(context)
                        : S.of(context).reclassifyDisabledImages,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  key: const ValueKey('maintenance-rebuild-button'),
                  onPressed: () => unawaited(onRebuildIndex()),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(S.of(context).recreateDatabase),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  key: const ValueKey('maintenance-clear-button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => unawaited(onClearImages()),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(S.of(context).clearImages),
                ),
              ],
            ),
    );
  }
}

class _AdaptiveSwitchTile extends StatelessWidget {
  const _AdaptiveSwitchTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelStrong,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.outline),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.sectionKey,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Key? sectionKey;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: sectionKey,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}
