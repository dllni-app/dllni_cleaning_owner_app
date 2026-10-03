import 'package:flutter/material.dart';

import '../../../../core/widgets/worker_screen_header.dart';

class CalenderAppBar extends StatelessWidget {
  const CalenderAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkerScreenHeader(
      title: 'تقويمي',
      padding: EdgeInsetsDirectional.fromSTEB(20, 8, 20, 12),
    );
  }
}
