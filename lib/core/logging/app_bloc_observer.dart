import 'package:bloc/bloc.dart';
import 'package:lightshot_parser_mobile/core/logging/app_logger.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_cubit.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    AppLogger.info('Created ${bloc.runtimeType}', scope: 'bloc');
    super.onCreate(bloc);
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    AppLogger.info('${bloc.runtimeType} event: $event', scope: 'bloc');
    super.onEvent(bloc, event);
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    if (bloc is GalleryCubit) {
      super.onChange(bloc, change);
      return;
    }

    AppLogger.info(
      '${bloc.runtimeType} state: ${change.currentState} -> ${change.nextState}',
      scope: 'bloc',
    );
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLogger.error(
      '${bloc.runtimeType} error',
      scope: 'bloc',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    AppLogger.info('Closed ${bloc.runtimeType}', scope: 'bloc');
    super.onClose(bloc);
  }
}
