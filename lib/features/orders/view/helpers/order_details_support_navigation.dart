import 'package:common_package/common_package.dart';
import 'package:flutter/widgets.dart';

import '../screens/emergency_sos_screen.dart';

void openOrderUrgentSupport(BuildContext context, int bookingId) {
  context.pushRoute(
    '/emergencysos',
    arguments: EmergencySosScreenParams(bookingId: bookingId),
  );
}
