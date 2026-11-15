import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartObserver extends BlocObserver {
  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    debugPrint(
      '${bloc.runtimeType}: ${transition.currentState.itemCount} items '
      '--${transition.event.runtimeType}--> '
      '${transition.nextState.itemCount} items',
    );
  }
}