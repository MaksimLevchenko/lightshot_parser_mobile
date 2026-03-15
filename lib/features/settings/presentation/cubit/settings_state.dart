import 'package:equatable/equatable.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/app_settings.dart';

enum SettingsSaveStatus {
  idle,
  saving,
  success,
  failure,
}

class SettingsState extends Equatable {
  const SettingsState({
    required this.draft,
    required this.saveStatus,
    this.errorMessage,
  });

  const SettingsState.initial()
      : draft = const AppSettings.initial(),
        saveStatus = SettingsSaveStatus.idle,
        errorMessage = null;

  final AppSettings draft;
  final SettingsSaveStatus saveStatus;
  final String? errorMessage;

  SettingsState copyWith({
    AppSettings? draft,
    SettingsSaveStatus? saveStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SettingsState(
      draft: draft ?? this.draft,
      saveStatus: saveStatus ?? this.saveStatus,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [draft, saveStatus, errorMessage];
}
