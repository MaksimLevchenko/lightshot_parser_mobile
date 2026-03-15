import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
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

  void setSelectedSource(DownloadSource value) {
    emit(state.copyWith(draft: state.draft.copyWith(selectedSource: value)));
  }

  void setWantedNumOfImages(int value) {
    emit(state.copyWith(draft: state.draft.copyWith(wantedNumOfImages: value)));
  }

  void setUseNewAddresses(bool value) {
    final maxLength = value ? 12 : 6;
    var startingId = state.draft.lightshot.startingId;
    if (startingId.length > maxLength) {
      startingId = startingId.substring(0, maxLength);
    }
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          lightshot: state.draft.lightshot.copyWith(
            useNewAddresses: value,
            startingId: startingId,
          ),
        ),
      ),
    );
  }

  void setUseRandomAddress(bool value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          lightshot: state.draft.lightshot.copyWith(
            useRandomAddress: value,
            startingId: value ? '' : state.draft.lightshot.startingId,
          ),
        ),
      ),
    );
  }

  void setStartingUrl(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          lightshot: state.draft.lightshot.copyWith(startingId: value),
        ),
      ),
    );
  }

  void setImgurIdLength(int value) {
    final normalizedLength = value == 7 ? 7 : 5;
    var startingId = state.draft.imgur.startingId;
    if (startingId.length > normalizedLength) {
      startingId = startingId.substring(0, normalizedLength);
    }
    final candidateLengths = <int>[
      normalizedLength,
      ...state.draft.imgur.candidateLengths.where(
        (length) => length != normalizedLength,
      ),
    ];
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          imgur: state.draft.imgur.copyWith(
            candidateLengths: candidateLengths,
            startingId: startingId,
          ),
        ),
      ),
    );
  }

  void setImgurUseRandomAddress(bool value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          imgur: state.draft.imgur.copyWith(
            useRandomAddress: value,
            startingId: value ? '' : state.draft.imgur.startingId,
          ),
        ),
      ),
    );
  }

  void setImgurStartingId(String value) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          imgur: state.draft.imgur.copyWith(startingId: value),
        ),
      ),
    );
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
        lightshot: state.draft.lightshot.copyWith(
          startingId: state.draft.lightshot.useRandomAddress
              ? ''
              : state.draft.lightshot.startingId,
        ),
        imgur: state.draft.imgur.copyWith(
          startingId: state.draft.imgur.useRandomAddress
              ? ''
              : state.draft.imgur.startingId,
        ),
      );
      await _settingsRepository.save(normalizedSettings);
      emit(
        state.copyWith(
          draft: normalizedSettings,
          saveStatus: SettingsSaveStatus.success,
          clearError: true,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
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
