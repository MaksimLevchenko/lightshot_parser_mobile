import 'package:equatable/equatable.dart';

enum BootstrapStatus {
  initial,
  loading,
  ready,
  failure,
}

class BootstrapState extends Equatable {
  const BootstrapState({
    required this.status,
    this.errorMessage,
  });

  const BootstrapState.initial()
      : status = BootstrapStatus.initial,
        errorMessage = null;

  final BootstrapStatus status;
  final String? errorMessage;

  BootstrapState copyWith({
    BootstrapStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BootstrapState(
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
