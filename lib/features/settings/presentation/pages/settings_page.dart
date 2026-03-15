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
import 'package:lightshot_parser_mobile/generated/l10n.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _wantedNumController;
  late final TextEditingController _lightshotStartingIdController;
  late final TextEditingController _imgurStartingIdController;
  late final TextEditingController _proxyAddressController;
  late final TextEditingController _proxyPortController;
  late final TextEditingController _proxyLoginController;
  late final TextEditingController _proxyPasswordController;

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
  }

  @override
  void dispose() {
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
            if (state.saveStatus == SettingsSaveStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                buildAppSnackBar(message: S.of(context).settingsSaved),
              );
              context.read<SettingsCubit>().clearSaveStatus();
            } else if (state.saveStatus == SettingsSaveStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                buildAppSnackBar(
                  message: S.of(context).pleaseEnterTheCorrectData,
                  backgroundColor: AppColors.error,
                ),
              );
              context.read<SettingsCubit>().clearSaveStatus();
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
            final draft = state.draft;
            final selectedSource = draft.selectedSource;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<DownloadSource>(
                      initialValue: selectedSource,
                      decoration: InputDecoration(
                        labelText: DownloadSourceTexts.sourceLabel(context),
                      ),
                      items: DownloadSource.values
                          .map(
                            (source) => DropdownMenuItem<DownloadSource>(
                              value: source,
                              child: Text(
                                DownloadSourceTexts.sourceName(
                                  context,
                                  source,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          context
                              .read<SettingsCubit>()
                              .setSelectedSource(value);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _wantedNumController,
                      decoration: InputDecoration(
                        labelText: S.of(context).numberOfImagesToDownload,
                        hintText:
                            S.of(context).enterTheNumberOfImagesToDownload,
                      ),
                      maxLength: 5,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          SettingsFormValidators.validateWantedNumOfImages(
                        context,
                        value,
                      ),
                      onChanged: (value) {
                        final parsedValue = int.tryParse(value);
                        if (parsedValue != null) {
                          context
                              .read<SettingsCubit>()
                              .setWantedNumOfImages(parsedValue);
                        }
                      },
                    ),
                    _SourceSettingsSection(
                      title: selectedSource == DownloadSource.lightshot
                          ? DownloadSourceTexts.lightshotSettings(context)
                          : DownloadSourceTexts.imgurSettings(context),
                      child: selectedSource == DownloadSource.lightshot
                          ? Column(
                              children: [
                                CheckboxListTile(
                                  value: draft.lightshot.useNewAddresses,
                                  onChanged: (value) {
                                    final useNewAddresses = value ?? false;
                                    final maxLength = useNewAddresses ? 12 : 6;
                                    if (_lightshotStartingIdController
                                            .text.length >
                                        maxLength) {
                                      _lightshotStartingIdController.text =
                                          _lightshotStartingIdController.text
                                              .substring(0, maxLength);
                                      _lightshotStartingIdController.selection =
                                          TextSelection.collapsed(
                                        offset: _lightshotStartingIdController
                                            .text.length,
                                      );
                                    }
                                    context
                                        .read<SettingsCubit>()
                                        .setUseNewAddresses(useNewAddresses);
                                  },
                                  title: Text(S.of(context).useNewAddresses),
                                ),
                                CheckboxListTile(
                                  value: draft.lightshot.useRandomAddress,
                                  onChanged: (value) {
                                    final useRandomAddress = value ?? false;
                                    if (useRandomAddress) {
                                      _lightshotStartingIdController.clear();
                                    }
                                    context
                                        .read<SettingsCubit>()
                                        .setUseRandomAddress(
                                          useRandomAddress,
                                        );
                                  },
                                  title: Text(S.of(context).useRandomAddresses),
                                ),
                                TextFormField(
                                  controller: _lightshotStartingIdController,
                                  enabled: !draft.lightshot.useRandomAddress,
                                  decoration: InputDecoration(
                                    labelText: S.of(context).startingAddress,
                                    hintText:
                                        S.of(context).enterTheStartingAddress,
                                  ),
                                  maxLength: draft.lightshot.idLength,
                                  validator: (value) => SettingsFormValidators
                                      .validateStartingUrl(
                                    context,
                                    useRandomAddress:
                                        draft.lightshot.useRandomAddress,
                                    useNewAddresses:
                                        draft.lightshot.useNewAddresses,
                                    value: value,
                                  ),
                                  onChanged: context
                                      .read<SettingsCubit>()
                                      .setStartingUrl,
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                DropdownButtonFormField<int>(
                                  initialValue: draft.imgur.idLength,
                                  decoration: InputDecoration(
                                    labelText:
                                        DownloadSourceTexts.imgurIdLength(
                                      context,
                                    ),
                                  ),
                                  items: const [5, 7]
                                      .map(
                                        (value) => DropdownMenuItem<int>(
                                          value: value,
                                          child: Text('$value'),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) {
                                    if (value == null) {
                                      return;
                                    }
                                    if (_imgurStartingIdController.text.length >
                                        value) {
                                      _imgurStartingIdController.text =
                                          _imgurStartingIdController.text
                                              .substring(0, value);
                                      _imgurStartingIdController.selection =
                                          TextSelection.collapsed(
                                        offset: _imgurStartingIdController
                                            .text.length,
                                      );
                                    }
                                    context
                                        .read<SettingsCubit>()
                                        .setImgurIdLength(value);
                                  },
                                ),
                                CheckboxListTile(
                                  value: draft.imgur.useRandomAddress,
                                  onChanged: (value) {
                                    final useRandomAddress = value ?? false;
                                    if (useRandomAddress) {
                                      _imgurStartingIdController.clear();
                                    }
                                    context
                                        .read<SettingsCubit>()
                                        .setImgurUseRandomAddress(
                                          useRandomAddress,
                                        );
                                  },
                                  title: Text(S.of(context).useRandomAddresses),
                                ),
                                TextFormField(
                                  controller: _imgurStartingIdController,
                                  enabled: !draft.imgur.useRandomAddress,
                                  decoration: InputDecoration(
                                    labelText:
                                        DownloadSourceTexts.startingId(context),
                                    hintText:
                                        DownloadSourceTexts.enterTheStartingId(
                                      context,
                                    ),
                                  ),
                                  maxLength: draft.imgur.idLength,
                                  validator: (value) => SettingsFormValidators
                                      .validateImgurStartingId(
                                    context,
                                    useRandomAddress:
                                        draft.imgur.useRandomAddress,
                                    idLength: draft.imgur.idLength,
                                    value: value,
                                  ),
                                  onChanged: context
                                      .read<SettingsCubit>()
                                      .setImgurStartingId,
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CheckboxListTile(
                      value: draft.proxySettings.enabled,
                      onChanged: (value) => context
                          .read<SettingsCubit>()
                          .setUseProxy(value ?? false),
                      title: Text(S.of(context).useProxy),
                    ),
                    if (draft.proxySettings.enabled) ...[
                      CheckboxListTile(
                        value: draft.proxySettings.useAuthentication,
                        onChanged: (value) => context
                            .read<SettingsCubit>()
                            .setUseProxyAuth(value ?? false),
                        title: Text(S.of(context).useProxyAuth),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _proxyAddressController,
                              decoration: InputDecoration(
                                labelText: S.of(context).proxyAddress,
                                hintText: S.of(context).enterTheProxyAddress,
                              ),
                              validator: (value) =>
                                  SettingsFormValidators.validateProxyAddress(
                                context,
                                value,
                              ),
                              onChanged:
                                  context.read<SettingsCubit>().setProxyAddress,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _proxyPortController,
                              decoration: InputDecoration(
                                labelText: S.of(context).proxyPort,
                                hintText: S.of(context).enterTheProxyPort,
                              ),
                              validator: (value) =>
                                  SettingsFormValidators.validateProxyPort(
                                context,
                                value,
                              ),
                              onChanged:
                                  context.read<SettingsCubit>().setProxyPort,
                            ),
                          ),
                        ],
                      ),
                      if (draft.proxySettings.useAuthentication) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _proxyLoginController,
                                decoration: InputDecoration(
                                  labelText: S.of(context).proxyLogin,
                                  hintText: S.of(context).enterTheProxyLogin,
                                ),
                                validator: (value) =>
                                    SettingsFormValidators.validateRequired(
                                  value,
                                  S.of(context).pleaseEnterTheProxyLogin,
                                ),
                                onChanged:
                                    context.read<SettingsCubit>().setProxyLogin,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: TextFormField(
                                controller: _proxyPasswordController,
                                decoration: InputDecoration(
                                  labelText: S.of(context).proxyPassword,
                                  hintText: S.of(context).enterTheProxyPassword,
                                ),
                                validator: (value) =>
                                    SettingsFormValidators.validateRequired(
                                  value,
                                  S.of(context).pleaseEnterTheProxyPassword,
                                ),
                                onChanged: context
                                    .read<SettingsCubit>()
                                    .setProxyPassword,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: state.saveStatus == SettingsSaveStatus.saving
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                context.read<SettingsCubit>().save();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  buildAppSnackBar(
                                    message:
                                        S.of(context).pleaseEnterTheCorrectData,
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            },
                      child: Text(S.of(context).save),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              context.read<GalleryCubit>().rebuildIndex(),
                          child: Text(S.of(context).recreateDatabase),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<GalleryCubit>().clearImages(),
                          child: Text(S.of(context).clearImages),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SourceSettingsSection extends StatelessWidget {
  const _SourceSettingsSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        child,
      ],
    );
  }
}
