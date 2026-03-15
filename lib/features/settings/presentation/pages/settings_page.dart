import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lightshot_parser_mobile/core/theme/app_theme.dart';
import 'package:lightshot_parser_mobile/core/widgets/app_snack_bar.dart';
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
  late final TextEditingController _startingUrlController;
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
    _startingUrlController = TextEditingController(text: draft.startingUrl);
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
    _startingUrlController.dispose();
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
            if (state.message == 'reindexed') {
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
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
                    CheckboxListTile(
                      value: draft.useNewAddresses,
                      onChanged: (value) {
                        final useNewAddresses = value ?? false;
                        final maxLength = useNewAddresses ? 12 : 6;
                        if (_startingUrlController.text.length > maxLength) {
                          _startingUrlController.text = _startingUrlController
                              .text
                              .substring(0, maxLength);
                          _startingUrlController.selection =
                              TextSelection.collapsed(
                            offset: _startingUrlController.text.length,
                          );
                        }
                        context
                            .read<SettingsCubit>()
                            .setUseNewAddresses(useNewAddresses);
                      },
                      title: Text(S.of(context).useNewAddresses),
                    ),
                    CheckboxListTile(
                      value: draft.useRandomAddress,
                      onChanged: (value) {
                        final useRandomAddress = value ?? false;
                        if (useRandomAddress) {
                          _startingUrlController.clear();
                        }
                        context
                            .read<SettingsCubit>()
                            .setUseRandomAddress(useRandomAddress);
                      },
                      title: Text(S.of(context).useRandomAddresses),
                    ),
                    TextFormField(
                      controller: _startingUrlController,
                      enabled: !draft.useRandomAddress,
                      decoration: InputDecoration(
                        labelText: S.of(context).startingAddress,
                        hintText: S.of(context).enterTheStartingAddress,
                      ),
                      maxLength: draft.useNewAddresses ? 12 : 6,
                      validator: (value) =>
                          SettingsFormValidators.validateStartingUrl(
                        context,
                        useRandomAddress: draft.useRandomAddress,
                        useNewAddresses: draft.useNewAddresses,
                        value: value,
                      ),
                      onChanged: context.read<SettingsCubit>().setStartingUrl,
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
