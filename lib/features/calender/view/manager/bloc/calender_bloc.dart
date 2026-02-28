import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'calender_event.dart';
part 'calender_state.dart';

@injectable
class CalenderBloc extends Bloc<CalenderEvent, CalenderState> {
  CalenderBloc() : super(CalenderState()) {
    on<CalenderEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
