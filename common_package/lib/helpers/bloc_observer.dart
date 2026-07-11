import 'package:common_package/helpers/app_log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    appLog('Create ---> ${bloc.runtimeType}');
    super.onCreate(bloc);
  }

  @override
  void onClose(BlocBase bloc) {
    appLog('Close ---> ${bloc.runtimeType}');
    super.onClose(bloc);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    appLog(
      'Error  occurred in ${bloc.runtimeType}\n'
      '-----------------StackTrace--------------------\n'
      '${stackTrace.toString()}',
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    appLog(
      '-----------------Bloc Transition------------------------\n'
      'bloc: ${bloc.runtimeType}\n'
      'Event: ${transition.event.runtimeType}\n'
      'CurrentState: ${transition.currentState.runtimeType}: ${transition.currentState.toString()} \n'
      'NextState: ${transition.nextState.runtimeType}: ${transition.nextState.toString()} \n'
      '----------------------------------------------------------\n',
    );

    super.onTransition(bloc, transition);
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    appLog(
      '--------------------------Bloc Event-----------------------\n'
      'bloc: ${bloc.runtimeType}\n'
      'event: ${event.runtimeType}\n'
      '-------------------------------------------------------------\n',
    );
    super.onEvent(bloc, event);
  }
}
