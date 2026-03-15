import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/cubit/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._settingsRepository)
      : super(
          SettingsState(
            draft: _settingsRepository.currentSettings,
            saveStatus: SettingsSaveStatus.idle,
          ),
        );

  final SettingsRepository _settingsRepository;

  void setWantedNumOfImages(int value) {
    emit(state.copyWith(draft: state.draft.copyWith(wantedNumOfImages: value)));
  }

  void setUseNewAddresses(bool value) {
    final maxLength = value ? 12 : 6;
    var startingUrl = state.draft.startingUrl;
    if (startingUrl.length > maxLength) {
      startingUrl = startingUrl.substring(0, maxLength);
    }
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          useNewAddresses: value,
          startingUrl: startingUrl,
        ),
      ),
    );
  }

  void setUseRandomAddress(bool value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          useRandomAddress: value,
          startingUrl: value ? '' : state.draft.startingUrl,
        ),
      ),
    );
  }

  void setStartingUrl(String value) {
    emit(state.copyWith(draft: state.draft.copyWith(startingUrl: value)));
  }

  void setUseProxy(bool value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          proxySettings: state.draft.proxySettings.copyWith(enabled: value),
        ),
      ),
    );
  }

  void setUseProxyAuth(bool value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          proxySettings:
              state.draft.proxySettings.copyWith(useAuthentication: value),
        ),
      ),
    );
  }

  void setProxyAddress(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          proxySettings: state.draft.proxySettings.copyWith(address: value),
        ),
      ),
    );
  }

  void setProxyPort(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          proxySettings: state.draft.proxySettings.copyWith(port: value),
        ),
      ),
    );
  }

  void setProxyLogin(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          proxySettings: state.draft.proxySettings.copyWith(login: value),
        ),
      ),
    );
  }

  void setProxyPassword(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          proxySettings: state.draft.proxySettings.copyWith(password: value),
        ),
      ),
    );
  }

  Future<void> save() async {
    emit(state.copyWith(
        saveStatus: SettingsSaveStatus.saving, clearError: true));
    try {
      final normalizedSettings = state.draft.copyWith(
        startingUrl:
            state.draft.useRandomAddress ? '' : state.draft.startingUrl,
      );
      await _settingsRepository.save(normalizedSettings);
      emit(
        state.copyWith(
          draft: normalizedSettings,
          saveStatus: SettingsSaveStatus.success,
          clearError: true,
        ),
      );
    } on Object catch (error) {
      emit(
        state.copyWith(
          saveStatus: SettingsSaveStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void clearSaveStatus() {
    emit(
      state.copyWith(
        saveStatus: SettingsSaveStatus.idle,
        clearError: true,
      ),
    );
  }
}
